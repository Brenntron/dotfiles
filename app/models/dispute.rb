class Dispute < ApplicationRecord
  has_paper_trail on: [:update], ignore: [:updated_at]
  has_many :dispute_comments
  has_many :dispute_emails
  has_many :dispute_entries
  belongs_to :customer
  belongs_to :user

  delegate :cvs_username, to: :user, allow_nil: true

  NEW = 'new'
  RESOLVED = 'resolved'
  ASSIGNED = 'assigned'

  def is_assigned?
    (!self.user.blank? && self.user.email != 'vrt-incoming@sourcefire.com')
  end

  def assignee
    is_assigned? ? user.email : "Unassigned"
  end

  def suggested_d
    # had this as an unless earlier ... also, the .first should be replaced by some sort
    # of null coalesece
    if dispute_entries.empty? or dispute_entries.first[:suggested_disposition].nil?
      "None"
    else
      dispute_entries.first[:suggested_disposition]
    end
  end

  def entry_count
    dispute_entries.length
  end

  def dispute_age
    return '' unless self.case_opened_at
    age = self.case_opened_at - DateTime.now
    age = age.abs # lazy
    mm, ss = age.divmod(60)
    hh, mm = mm.divmod(60)
    dd, hh = hh.divmod(24)
    if dd > 0
      "%dd %dh" % [dd, hh]
    elsif hh > 0
      "%dh %dm" % [hh, mm]
    else
      "%dm %ds" % [mm, ss]
    end
  end

  def self.parse_url(url)
    pre_url = url.gsub("http://", "").gsub("https://", "")
    url = "http://" + pre_url

    uri_parts = {}

    uri_object = URI(url)

    domain_parts = uri_object.host.split(".")
    if domain_parts > 2
      uri_parts[:subdomain] = domain_parts.first
      uri_parts[:domain] = domain_parts - [domain_parts.first]
      uri_parts[:path] = uri_object.path
    else
      uri_parts[:subdomain] = ""
      uri_parts[:domain] = uri_object.host
      uri_parts[:path] = uri_object.path
    end


    uri_parts
  end

  def self.is_possible_company_duplicate?(dispute, entry, entry_type)
    company_id = dispute.customer.company.id

    candidates = Dispute.includes(:customer).includes(:dispute_entries).where(:status != RESOLVED, :customers => {:company_id => company_id}, :dispute_entries => {:entry_type => entry_type})

    if candidates.blank?
      return false
    end

    candidates.each do |candidate|
      if entry_type == "IP"
        possible_duplicates = candidate.dispute_entries.any? {|entry| entry.ip_address == entry}
      end

      if entry_type == "URI/DOMAIN"
        possible_duplicates = candidate.dispute_entries.any? {|entry| entry.hostname == entry}
      end

    end

    return possible_duplicates.present?
  end

  def compose_versioned_items

    versioned_items = [self]

    dispute_comments.includes(:versions).map{ |dc| versioned_items << dc}
    dispute_entries.includes(:versions).map{ |de| versioned_items << de}

    versioned_items

  end

  def self.process_bridge_payload(message_payload)
    user = User.where(cvs_username:"vrtincom").first
    #TODO: this should be put in a params method
    message_payload["payload"] = message_payload["payload"].permit!.to_h
    new_entries_ips = message_payload["payload"]["investigate_ips"].permit!.to_h
    new_entries_urls = message_payload["payload"]["investigate_urls"].permit!.to_h

    return_payload = {}


    #BIG TO DO:  RESEARCH!!!
    #auto rep dispute resolution
    #apparently there is logic we need to employ where cross referencing a URL
    #with virustotal and umbrella/opendns for negative malicious based rulehits
    #will be grounds for creating a new dispute case, resolving it, automated resolution message
    #and setting appropriate entries into RepTool to adjust the reptuation...possibly RuleUI WL/BL as well?
    #need to ask

    #create an escalations IP/DOMAIN bugzilla bug here and transfer id to new dispute

    bug_factory = Bugzilla::Bug.new(message_payload[:bugzilla_session])

    summary = "New Web Reputation Dispute generated at #{DateTime.now.utc.strftime("%Y-%m-%d %H:%M")}"

    full_description = %Q{
      IPs: #{new_entries_ips.map {|key, data| key.to_s}.join(', ')}
      URIs: #{new_entries_urls.map {|key, data| key.to_s}.join(', ')}
      Problem Summary: #{message_payload["payload"]["problem"]}
    }

    bug_attrs = {
        'product' => 'Escalations',
        'component' => 'IP/Domain',
        'summary' => summary,
        'version' => 'unspecified', #self.version,
        'description' => full_description,
        # 'opsys' => self.os,
        'priority' => 'Unspecified',
        'classification' => 'unclassified',
    }

    bug_stub_hash = Bug.bugzilla_create(bug_factory, bug_attrs, user: user)

    new_dispute = Dispute.new
    new_dispute.submission_type = message_payload["payload"]["submission_type"]
    new_dispute.id = bug_stub_hash["id"]
    new_dispute.user_id = user.id
    new_dispute.customer_name = message_payload["payload"]["name"]
    new_dispute.source_ip_address = message_payload["payload"]["user_ip"]
    new_dispute.customer_email = message_payload["payload"]["email"]
    new_dispute.org_domain = message_payload["payload"]["domain"]
    new_dispute.case_opened_at = Time.now
    new_dispute.subject = message_payload["payload"]["email_subject"]
    new_dispute.description = message_payload["payload"]["email_body"]
    new_dispute.problem_summary = message_payload["payload"]["problem"]
    new_dispute.ticket_source_key = message_payload["source_key"]
    new_dispute.ticket_source = "talos-intelligence"
    new_dispute.ticket_source_type = message_payload["source_type"]
    new_dispute.submission_type = message_payload["submission_type"]  # email, web, both  [e|w|ew]

    new_dispute.customer_id = Customer.process_and_get_customer(message_payload).id

    new_dispute.save

    #IPS and URL/DOMAIN entries are almost virtually the same, maybe this is worthy of refactoring into it's own method.
    #TODO:  answer the above question later and if the answer is it's eligible for consolidating into one method, do so.

    new_entries_ips.each do |key, entry|

      #this is for return back to TI to populate its ticket show pages
      new_payload_item = {}
      new_payload_item[:sugg_type] = entry["rep_sugg"]
      new_payload_item[:status] = "pending"
      new_payload_item[:resolution_message] = ""
      new_payload_item[:resolution] = ""
      new_payload_item[:company_dup] = is_possible_company_duplicate?(new_dispute, key, "IP")
      return_payload[key] = new_payload_item

      new_dispute_entry = DisputeEntry.new
      new_dispute_entry.dispute_id = new_dispute.id
      new_dispute_entry.ip_address = key
      new_dispute_entry.entry_type = "IP"
      #new_dispute_entry.score_type = "SBRS"
      #new_dispute_entry.score = entry["SBRS_SCORE"].to_f
      new_dispute_entry.sbrs_score = entry[:sbrs]["SBRS_SCORE"]
      new_dispute_entry.wbrs_score = entry[:wbrs]["WBRS_SCORE"] 
      new_dispute_entry.suggested_disposition = entry["rep_sugg"]
      new_dispute_entry.save

      if entry[:sbrs]["SBRS_Rule_Hits"].present?
        all_hits = entry["SBRS_Rule_Hits"].split(",")
        all_hits.each do |rule_hit|
          new_rule_hit = DisputeRuleHit.new
          new_rule_hit.dispute_entry_id = new_dispute_entry.id
          new_rule_hit.name = rule_hit.strip
          new_rule_hit.rule_type = "sbrs"
          new_rule_hit.save
        end
      end
      if entry[:sbrs]["WBRS_Rule_Hits"].present?
        all_hits = entry["WBRS_Rule_Hits"].split(",")
        all_hits.each do |rule_hit|
          new_rule_hit = DisputeRuleHit.new
          new_rule_hit.dispute_entry_id = new_dispute_entry.id
          new_rule_hit.name = rule_hit.strip
          new_rule_hit.rule_type = "wbrs"
          new_rule_hit.save
        end
      end

    end

    new_entries_urls.each do |key, entry|

      #this is for return back to TI to populate its ticket show pages



      url_parts = Dispute.parse_url(key)
      new_dispute_entry = DisputeEntry.new
      new_dispute_entry.dispute_id = new_dispute.id
      new_dispute_entry.uri = key
      new_dispute_entry.wbrs_score = entry["wbrs_score"]
      new_dispute_entry.sbrs_score = entry["sbrs_score"]
      new_dispute_entry.suggested_disposition = entry["rep_sugg"]
      new_dispute_entry.subdomain = url_parts[:subdomain]
      new_dispute_entry.domain = url_parts[:domain]
      new_dispute_entry.path = url_parts[:path]
      new_dispute_entry.hostname = "#{url_parts[:subdomain]}.#{url_parts[:domain]}"
      new_dispute_entry.entry_type = "URI/DOMAIN"
      new_dispute_entry.save

      new_payload_item = {}
      new_payload_item[:sugg_type] = entry["rep_sugg"]
      new_payload_item[:status] = "pending"
      new_payload_item[:resolution_message] = ""
      new_payload_item[:resolution] = ""
      new_payload_item[:company_dup] = is_possible_company_duplicate(new_dispute, new_dispute_entry.hostname, "URI/DOMAIN")
      return_payload[key] = new_payload_item

      if entry["WBRS_Rule_Hits"].present?
        all_hits = entry["WBRS_Rule_Hits"].split(",")
        all_hits.each do |rule_hit|
          new_rule_hit = DisputeRuleHit.new
          new_rule_hit.dispute_entry_id = new_dispute_entry.id
          new_rule_hit.name = rule_hit.strip
          new_rule_hit.save
        end
      end

    end


    #build first official email of the new case

    first_email = DisputeEmail.new
    first_email.dispute_id = new_dispute.id
    first_email.email_headers = nil
    first_email.from = message_payload["payload"]["email"]
    first_email.to = nil
    first_email.subject = message_payload["payload"]["email_subject"]
    first_email.body = message_payload["payload"]["email_body"]
    first_email.status = DisputeEmail::UNREAD
    first_email.save


    case_email = DisputeEmail.generate_case_email_address(new_dispute.id)
    #change this
    return_message = {
      "envelope":
          {
              "channel": "ticket-acknowledge",
              "addressee": "talos-intelligence",
              "sender": "analyst-console"
          },
      "message": {"source_key":params["source_key"],"ac_status":"CREATE_ACK", "ticket_entries": return_payload, "case_email": case_email}
    }
  end

  def self.age_to_seconds(age_str)
    days =
        if /(?<days_str>\d+)[Dd]/ =~ age_str
          days_str.to_i
        else
          0
        end
    hours =
        if /(?<hours_str>\d+)[Hh]/ =~ age_str
          hours_str.to_i
        else
          0
        end
    (days * 24 + hours) * 3600
  end

  def self.save_named_search(search_name, params, user:)
    named_search =
        user.named_searches.where(name: search_name).first || NamedSearch.create!(user: user, name: search_name)
    NamedSearchCriterion.where(named_search: named_search).delete_all
    params.each do |field_name, value|
      case
        when value.kind_of?(Hash)
          value.each do |sub_field_name, sub_value|
            named_search.named_search_criteria.create(field_name: "#{field_name}~#{sub_field_name}", value: sub_value)
          end
        when 'search_type' == field_name
          #do nothing
        when 'search_name' == field_name
          #do nothing
        else
          named_search.named_search_criteria.create(field_name: field_name, value: value)
      end
    end
  end

  # Searches based on supplied fields and values.
  # Optionally takes a name to save this search as a saved search.
  # @param [ActionController::Parameters] params supplied fields and values for search.
  # @param [String] search_name name to save this search as a saved search.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.advanced_search(params, search_name:, user:)

    dispute_fields = params.to_h.slice(*%w{status org_domain priority resolution submitter_type case_id case_owner_username})
    dispute_fields['id'] = dispute_fields.delete('case_id')

    if dispute_fields['priority'] && /(?<priority_digits>\d+)/ =~ dispute_fields.delete('priority')
      dispute_fields['priority'] = priority_digits
    end

    if dispute_fields['case_owner_username'].present?
      user = User.where(cvs_username: dispute_fields.delete('case_owner_username')).first
      dispute_fields['user_id'] = user.id
    end

    dispute_fields = dispute_fields.select{|ignore_key, value| value.present?}
    relation = where(dispute_fields)


    if params['submitted_newer'].present?
      relation =
          relation.where('case_opened_at >= :submitted_newer', submitted_newer: params['submitted_newer'])
    end

    if params['submitted_older'].present?
      relation =
          relation.where('case_opened_at < :submitted_older', submitted_older: params['submitted_older']+1)
    end

    if params['age_newer'].present?
      seconds_ago = age_to_seconds(params['age_newer'])
      unless 0 == seconds_ago
        age_newer_cutoff = Time.now - seconds_ago
        relation =
            relation.where('case_opened_at >= :submitted_newer', submitted_newer: age_newer_cutoff)

      end
    end

    if params['age_older'].present?
      seconds_ago = age_to_seconds(params['age_older'])
      unless 0 == seconds_ago
        age_older_cutoff = Time.now - seconds_ago
        relation =
            relation.where('case_opened_at < :submitted_older', submitted_older: age_older_cutoff)
      end
    end

    if params['modified_newer'].present?
      relation =
          relation.where('updated_at >= :modified_newer', modified_newer: params['modified_newer'])
    end

    if params['modified_older'].present?
      relation =
          relation.where('updated_at < :modified_older', modified_older: params['modified_older']+1)
    end



    company_name = nil
    customer_params = params.fetch('customer', {}).slice(*%w{name email company_name})
    customer_params = customer_params.select{|ignore_key, value| value.present?}
    if customer_params.any?
      if customer_params['company_name'].present?
        company_name = customer_params.delete('company_name')
        relation = relation.joins(customer: :company)
      else
        relation = relation.joins(:customer)
      end

      customer_where = customer_params
      if company_name.present?
        customer_where = customer_where.merge(companies: {name: company_name})
      end
      relation = relation.where(customers: customer_where)
    end

    entry_params = params.fetch('dispute_entries', {})
    entry_params = entry_params.select{|ignore_key, value| value.present?}
    if entry_params.any?
      dispute_entry_fields = entry_params.slice(*%w{suggested_disposition})
      ip_or_uri = entry_params['ip_or_uri']

      relation = relation.joins(:dispute_entries).group(:id)
      relation = relation.where(dispute_entries: dispute_entry_fields) if dispute_entry_fields.present?

      if ip_or_uri.present?
        ip_or_uri_clause = "dispute_entries.ip_address = :ip_or_uri OR dispute_entries.uri like :ip_or_uri_pattern"
        relation = relation.where(ip_or_uri_clause, ip_or_uri: ip_or_uri, ip_or_uri_pattern: "%#{ip_or_uri}%")
      end
    end

    # Save this search as a named search
    if params.present? && search_name.present?
      save_named_search(search_name, params, user: user)
    end

    relation
  end

  # Searched based on saved search.
  # @param [String] search_name the name of the saved search.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.named_search(search_name, user:)
    named_search = user.named_searches.where(name: search_name).first
    raise "No search named '#{search_name}' found." unless named_search
    search_params = named_search.named_search_criteria.inject({}) do |search_params, criterion|
      if /\A(?<super_name>[^~]*)~(?<sub_name>[^~]*)\z/ =~ criterion.field_name
        search_params[super_name] ||= {}
        search_params[super_name][sub_name] = criterion.value
      else
        search_params[criterion.field_name] = criterion.value
      end
      search_params
    end
    advanced_search(search_params, search_name: nil, user: user)
  end

  # Searches based on standard pre-determined filters.
  # @param [String] search_name name of the filter.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.standard_search(search_name, user:)
    case search_name
      when 'my_open'
        where(status: ['new', 'open', 'reopen'], user_id: user.id)
      when 'my_disputes'
        where(user_id: user.id)
      when 'team_disputes'
        where(user_id: user.my_team)
      when 'open'
        where(status: ['new', 'open', 'reopen'])
      when 'closed'
        where(status: ['closed', 'resolved'])
      when 'all'
        where({})
      else
        raise "No search named '#{search_name}' known."
    end
  end

  # Searches many fields in the record for values containing a given value.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.contains_search(value)
    searchable_fields = %w{case_number case_guid customer_name customer_email customer_phone customer_company_name
                           org_domain subject description problem_summary research_notes}
    where_str = searchable_fields.map{|field| "#{field} like :pattern"}.join(' or ')
    where(where_str, pattern: "%#{value}%")
  end

  # Searches in a variety of ways.
  # advanced -- search by supplied field.
  # named -- call a saved search.
  # standard -- use a pre-defined search.
  # contains -- search many fields where supplied value is contained in the field.
  # nil -- all records.
  # @param [String] search_type variety of search
  # @param [ActionController::Parameters] params supplied fields and values for search.
  # @param [String] search_name name of saved search.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.robust_search(search_type, search_name: nil, params: nil, user:)
    case search_type
      when 'advanced'
        advanced_search(params, search_name: search_name, user: user)
      when 'named'
        named_search(search_name, user: user)
      when 'standard'
        standard_search(search_name, user: user)
      when 'contains'
        contains_search(params['value'])
      else
        where({})
    end
  end
end

