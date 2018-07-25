class Dispute < ApplicationRecord
  has_paper_trail on: [:update], ignore: [:updated_at]

  belongs_to :customer
  belongs_to :user

  has_many :dispute_comments
  has_many :dispute_emails
  has_many :dispute_entries
  has_many :dispute_peeks, -> { order("dispute_peeks.updated_at desc") }
  has_many :recent_dispute_views, class_name: 'User', through: :dispute_peeks, source: :user

  delegate :cvs_username, to: :user, allow_nil: true

  NEW = 'NEW'
  RESOLVED = 'RESOLVED'
  ASSIGNED = 'ASSIGNED'
  CLOSED = 'CLOSED'

  ANALYST_COMPLETED = "Analyst Completed"
  ALL_AUTO_RESOLVED = "All Auto Resolved"

  TI_NEW = 'IN PROGRESS'
  TI_RESOLVED = 'RESOLVED'

  AC_SUCCESS = 'CREATE_ACK'
  AC_FAILED = 'CREATE_FAILED'
  AC_PENDING = 'CREATE_PENDING'

  SUBMITTER_TYPE_CUSTOMER = "CUSTOMER"
  SUBMITTER_TYPE_NONCUSTOMER = "NON-CUSTOMER"

  scope :open, -> { where(status: NEW) }
  scope :closed, -> { where(status: CLOSED) }
  scope :in_progress, -> { where.not(status: [ NEW, CLOSED ]) }
  scope :my_team, ->(user) { where(user_id: user.my_team) }

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
    if domain_parts.size > 2
      uri_parts[:subdomain] = domain_parts.first
      uri_parts[:domain] = (domain_parts - [domain_parts.first]).join('.')
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
    possible_duplicates = false
    candidates = Dispute.includes(:customer).includes(:dispute_entries).where("disputes.status != '#{RESOLVED}'").where(:customers => {:company_id => company_id}, :dispute_entries => {:entry_type => entry_type})

    if candidates.blank?
      return false
    end
    dispute.reload
    current_dispute_entries = dispute.dispute_entries

    candidates.each do |candidate|
      if entry_type == "IP"
        possible_duplicates = (candidate.dispute_entries - current_dispute_entries).any? {|dispute_entry| dispute_entry.ip_address == entry}
        if possible_duplicates == true
          return true
        end
      end

      if entry_type == "URI/DOMAIN"
        possible_duplicates = (candidate.dispute_entries - current_dispute_entries).any? {|dispute_entry| dispute_entry.uri == entry}
        if possible_duplicates == true
          return true
        end
      end

    end

    return possible_duplicates
  end

  def compose_versioned_items

    versioned_items = [self]

    dispute_comments.includes(:versions).map{ |dc| versioned_items << dc}
    dispute_entries.includes(:versions).map{ |de| versioned_items << de}

    versioned_items

  end

  def check_entries_and_resolve(new_resolution = nil)
    if new_resolution.blank?
      new_resolution = ANALYST_COMPLETED
    end
    is_resolved = true

    self.dispute_entries.each do |entry|
      if entry.status != RESOLVED
        is_resolved = false
        break
      end
    end

    if is_resolved == true
      self.status = Dispute::RESOLVED
      self.resolution = new_resolution
      save!
    end
  end

  #TODO: REFACTOR TO MAKE PROCESS_BRIDGE_PAYLOAD A SMALLER METHOD
  #These are instance methods used in building out the full dispute in a thread fired from self.process_bridge_payload
  #


  #
  #end dispute building instance methods
  #
  def self.process_bridge_payload(message_payload)
    verdicts_to_blacklist = []

    begin
      ActiveRecord::Base.transaction do

        logger.debug "Starting ticket create"

        user = User.where(cvs_username:"vrtincom").first
        guest = Company.where(:name => "Guest").first
        #TODO: this should be put in a params method
        message_payload["payload"] = message_payload["payload"].permit!.to_h
        new_entries_ips = message_payload["payload"]["investigate_ips"].permit!.to_h
        new_entries_urls = message_payload["payload"]["investigate_urls"].permit!.to_h

        return_payload = {}

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
        logger.debug "Creating bugzilla bug"

        bug_stub_hash = Bug.bugzilla_create(bug_factory, bug_attrs, user, true)

        logger.debug "Creating dispute"
        new_dispute = Dispute.new

        new_dispute.id = bug_stub_hash["id"]
        new_dispute.user_id = user.id
        new_dispute.source_ip_address = message_payload["payload"]["user_ip"]
        new_dispute.org_domain = message_payload["payload"]["domain"]
        new_dispute.case_opened_at = Time.now
        new_dispute.subject = message_payload["payload"]["email_subject"]
        new_dispute.description = message_payload["payload"]["email_body"]
        new_dispute.problem_summary = message_payload["payload"]["problem"]
        new_dispute.ticket_source_key = message_payload["source_key"]
        new_dispute.ticket_source = "talos-intelligence"
        new_dispute.ticket_source_type = message_payload["source_type"]
        new_dispute.submission_type = message_payload["payload"]["submission_type"]  # email, web, both  [e|w|ew]
        new_dispute.status = NEW

        new_dispute.customer_id = Customer.process_and_get_customer(message_payload).id

        new_dispute.submitter_type = new_dispute.customer.company_id == guest.id ? SUBMITTER_TYPE_NONCUSTOMER : SUBMITTER_TYPE_CUSTOMER

        if new_dispute.submitter_type == SUBMITTER_TYPE_CUSTOMER
          new_dispute.priority = "P3"
        else
          new_dispute.priority = "P4"
        end
        logger.debug "Saving Dispute"
        new_dispute.save

        #IPS and URL/DOMAIN entries are almost virtually the same, maybe this is worthy of refactoring into it's own method.
        #TODO:  answer the above question later and if the answer is it's eligible for consolidating into one method, do so.

        logger.debug "Creating ip entries"
        new_entries_ips.each do |key, entry|

          false_negative_claim = false

          if ["Malicious", "Poor"].include?(entry[:sbrs]["rep_sugg"])
            false_negative_claim = true
          end

          wbrs_hits = entry[:wbrs]["WBRS_Rule_Hits"].split(",").map {|hit| hit.strip }
          sbrs_hits = entry[:sbrs]["SBRS_Rule_Hits"].split(",").map {|hit| hit.strip }

          total_hits = (wbrs_hits + sbrs_hits).uniq

          auto_resolve_verdict = AutoResolve.create_from_payload("IP", key, total_hits)

          #this is for return back to TI to populate its ticket show pages
          new_payload_item = {}
          new_payload_item[:sugg_type] = entry["rep_sugg"]

          if false_negative_claim
            if auto_resolve_verdict.malicious?
              new_payload_item[:resolution_message] = "Talos has lowered our reputation score for the URL/Domain/Host to block access."
              new_payload_item[:resolution] = "FIXED"
              new_payload_item[:status] = TI_RESOLVED
            else
              new_payload_item[:resolution_message] = "The Talos web reputation will remain unchanged, based on available information. If you have further information regarding this URL/Domain/Host that indicates its involvement in malicious activity, please open an escalation with TAC and provide that information."
              new_payload_item[:resolution] = "UNCHANGED"
              new_payload_item[:status] = TI_RESOLVED
            end
          else
            new_payload_item[:status] = TI_NEW
            new_payload_item[:resolution_message] = ""
          end
          new_payload_item[:company_dup] = is_possible_company_duplicate?(new_dispute, key, "IP")
          return_payload[key] = new_payload_item

          new_dispute_entry = DisputeEntry.new
          new_dispute_entry.dispute_id = new_dispute.id
          new_dispute_entry.ip_address = key
          new_dispute_entry.entry_type = "IP"
          new_dispute_entry.sbrs_score = entry[:sbrs]["SBRS_SCORE"] == "No score" ? nil : entry[:sbrs]["SBRS_SCORE"]
          new_dispute_entry.wbrs_score = entry[:wbrs]["WBRS_SCORE"] == "No score" ? nil : entry[:sbrs]["WBRS_SCORE"]
          new_dispute_entry.suggested_disposition = entry[:sbrs]["rep_sugg"]

          if false_negative_claim
            if auto_resolve_verdict.malicious?
              new_dispute_entry.resolution_comment = "Talos has lowered our reputation score for the URL/Domain/Host to block access."
              new_dispute_entry.resolution = DisputeEntry::STATUS_RESOLVED_FIXED_FN
              new_dispute_entry.status = DisputeEntry::RESOLVED
            else
              new_dispute_entry.resolution_comment = "The Talos web reputation will remain unchanged, based on available information. If you have further information regarding this URL/Domain/Host that indicates its involvement in malicious activity, please open an escalation with TAC and provide that information."
              new_dispute_entry.resolution = DisputeEntry::STATUS_RESOLVED_FIXED_UNCHANGED
              new_dispute_entry.status = DisputeEntry::RESOLVED
            end
          else
            new_dispute_entry.status = DisputeEntry::NEW
          end
          new_dispute_entry.save

          if entry[:sbrs]["SBRS_Rule_Hits"].present?
            all_hits = entry[:sbrs]["SBRS_Rule_Hits"].split(",")
            all_hits.each do |rule_hit|
              new_rule_hit = DisputeRuleHit.new
              new_rule_hit.dispute_entry_id = new_dispute_entry.id
              new_rule_hit.name = rule_hit.strip
              new_rule_hit.rule_type = "sbrs"
              new_rule_hit.save
            end
          end
          if entry[:wbrs]["WBRS_Rule_Hits"].present?
            all_hits = entry[:wbrs]["WBRS_Rule_Hits"].split(",")
            all_hits.each do |rule_hit|
              new_rule_hit = DisputeRuleHit.new
              new_rule_hit.dispute_entry_id = new_dispute_entry.id
              new_rule_hit.name = rule_hit.strip
              new_rule_hit.rule_type = "wbrs"
              new_rule_hit.save
            end
          end

          verdicts_to_blacklist << [auto_resolve_verdict, new_dispute_entry]
          logger.debug "fetching preload"
          ::Preloader::Base.fetch_all_api_data(key, new_dispute_entry.id)

        end
        logger.debug "Creating url entries"
        new_entries_urls.each do |key, entry|

          #placeholder for preloading stuff from Micah
          #grab xbrs, reptool stuff, wl/bl entries, virustotal
          #

          false_negative_claim = false

          if ["Malicious", "Poor"].include?(entry["rep_sugg"])
            false_negative_claim = true
          end

          top_url = Wbrs::TopUrl.check_urls([key]).first

          #this is for return back to TI to populate its ticket show pages

          wbrs_hits = entry["WBRS_Rule_Hits"].split(",").map {|hit| hit.strip }


          total_hits = wbrs_hits

          auto_resolve_verdict = AutoResolve.create_from_payload("URI/DOMAIN", key, total_hits)

          url_parts = Dispute.parse_url(key)
          new_dispute_entry = DisputeEntry.new
          new_dispute_entry.dispute_id = new_dispute.id
          new_dispute_entry.uri = key
          new_dispute_entry.wbrs_score = entry["WBRS_SCORE"] == "No score" ? nil : entry["WBRS_SCORE"]
          new_dispute_entry.suggested_disposition = entry["rep_sugg"]
          new_dispute_entry.subdomain = url_parts[:subdomain]
          new_dispute_entry.domain = url_parts[:domain]
          new_dispute_entry.path = url_parts[:path]
          new_dispute_entry.hostname = "#{url_parts[:subdomain]}.#{url_parts[:domain]}"
          new_dispute_entry.entry_type = "URI/DOMAIN"
          new_dispute_entry.is_important = top_url.is_important != "invalid" ? top_url.is_important : false

          if false_negative_claim
            if auto_resolve_verdict.malicious?
              new_dispute_entry.resolution_comment = "Talos has lowered our reputation score for the URL/Domain/Host to block access."
              new_dispute_entry.resolution = DisputeEntry::STATUS_RESOLVED_FIXED_FN
              new_dispute_entry.status = DisputeEntry::RESOLVED
            else
              new_dispute_entry.resolution_comment = "The Talos web reputation will remain unchanged, based on available information. If you have further information regarding this URL/Domain/Host that indicates its involvement in malicious activity, please open an escalation with TAC and provide that information."
              new_dispute_entry.resolution = DisputeEntry::STATUS_RESOLVED_FIXED_UNCHANGED
              new_dispute_entry.status = DisputeEntry::RESOLVED
            end
          else
            new_dispute_entry.status = DisputeEntry::NEW
          end

          new_dispute_entry.save


          new_payload_item = {}
          new_payload_item[:sugg_type] = entry["rep_sugg"]
          if false_negative_claim
            if auto_resolve_verdict.malicious?
              new_payload_item[:resolution_message] = "Talos has lowered our reputation score for the URL/Domain/Host to block access."
              new_payload_item[:resolution] = "FIXED"
              new_payload_item[:status] = TI_RESOLVED
            else
              new_payload_item[:resolution_message] = "The Talos web reputation will remain unchanged, based on available information. If you have further information regarding this URL/Domain/Host that indicates its involvement in malicious activity, please open an escalation with TAC and provide that information."
              new_payload_item[:resolution] = "UNCHANGED"
              new_payload_item[:status] = TI_RESOLVED
            end
          else
            new_payload_item[:status] = TI_NEW
            new_payload_item[:resolution_message] = ""
          end
          new_payload_item[:company_dup] = is_possible_company_duplicate?(new_dispute, new_dispute_entry.hostname, "URI/DOMAIN")
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

          verdicts_to_blacklist << [auto_resolve_verdict, new_dispute_entry]
          logger.debug "fetching preload"
          ::Preloader::Base.fetch_all_api_data(key, new_dispute_entry.id)

        end

        new_dispute.check_entries_and_resolve(ALL_AUTO_RESOLVED)


        logger.debug "Creating email"
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
        logger.debug("Sending reply to bridge")
        conn = ::Bridge::DisputeCreatedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: message_payload["source_key"])
        conn.post(return_payload, case_email)

      end
    rescue Exception => e

      logger.debug("Failed.")
      Rails.logger.error "Dispute failed to save, backing out all DB changes."
      Rails.logger.error $!
      Rails.logger.error $!.backtrace.join("\n")

      conn = ::Bridge::DisputeFailedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: message_payload["source_key"])
      conn.post

    end


    verdicts_to_blacklist.each do |blacklist|
      begin
        auto_resolve_verdict = blacklist.first
        if auto_resolve_verdict.malicious?
          auto_resolve_verdict.publish_to_rep_api

          dispute_entry = blacklist.last

          args = {}
          args[:dispute_id] = dispute_entry.dispute_id
          args[:user_id] = user.id
          args[:comment] = auto_resolve_verdict.internal_comment

          DisputeComment.create(args)
        end
      rescue Exception => e
        Rails.logger.error "Attempts at blacklisting a dispute entry with reptool failed. Check reptool:"
        Rails.logger.error $!
        Rails.logger.error $!.backtrace.join("\n")

        dispute_entry = blacklist.last

        dispute_entry.status = NEW
        dispute_entry.resolution = ""
        dispute_entry.resolution_comment = ""
        dispute_entry.save

        args = {}
        args[:dispute_id] = dispute_entry.dispute_id
        args[:user_id] = user.id
        args[:comment] = "Dispute Entry #{dispute_entry.hostlookup} was eligible for auto-resolution, but failed to connect to RepTool. Sending this to the analysts' queue"

        DisputeComment.create(args)

      end
    end



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

  def self.standard_search_title(search_name)
    case search_name
      when 'recently_viewed'
        'Recently Viewed Tickets'
      when 'my_open'
        'My Open Tickets'
      when 'my_disputes'
        'My Tickets'
      when 'team_disputes'
        'My Team\'s Tickets'
      when 'open'
        'Open Tickets'
      when 'closed'
        'Closed Tickets'
      when 'all'
        'All Tickets'
      else
        raise "No search named '#{search_name}' known."
    end
  end

  # Searches based on standard pre-determined filters.
  # @param [String] search_name name of the filter.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.standard_search(search_name, user:)
    case search_name
      when 'recently_viewed'
        joins(:dispute_peeks).where(dispute_peeks: {user_id: user.id})
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
    dispute_fields = %w{case_number case_guid org_domain subject description
                        source_ip_address problem_summary research_notes}
    dispute_where = dispute_fields.map{|field| "#{field} like :pattern"}.join(' or ')

    customer_where = %w{name email}.map{|field| "customers.#{field} like :pattern"}.join(' or ')
    company_where = 'companies.name like :pattern'

    where_str = "#{dispute_where} or #{customer_where} or #{company_where}"
    left_joins(customer: :company).where(where_str, pattern: "%#{value}%")
  end

  def self.robust_search_title(search_type, search_name: nil)
    case search_type
      when 'advanced'
        search_name.present? ? search_name + ' Search' : 'Advanced Search'
      when 'named'
        search_name + ' Search'
      when 'standard'
        standard_search_title(search_name)
      when 'contains'
        'Substring Search'
      else
        'All Tickets'
    end
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

  def peek(user:)
    if dispute_peeks.where(user: user).exists?
      dispute_peeks.where(user: user).update_all(updated_at: Time.now)
    else
      dispute_peeks.create(user: user)
      DisputePeek.delete_excess(user: user)
    end
  end

  def take_ticket(user:)
    raise 'This ticket is already assigned.' unless self.user_id.nil? || User.vrtincoming&.id == self.user_id

    # Atomic update statement to handle possible race condition.
    Dispute.where(id: self.id,
                  user_id: self.user_id).update_all(user_id: user.id)

    dispute = Dispute.find(self.id)
    raise 'This record changed while you were editing.' unless dispute.user_id == user.id
  end

  def self.take_tickets(dispute_ids, user:)
    Dispute.transaction do
      unless Dispute.where(id: dispute_ids, user_id: User.vrtincoming.id)
        raise 'Some of these ticket are already assigned.'
      end

      Dispute.where(id: dispute_ids,
                    user_id: User.vrtincoming.id).update_all(user_id: user.id)

      unless dispute_ids.count == Dispute.where(id: dispute_ids, user_id: user.id).count
        raise 'This record changed while you were editing.'
      end
    end
  end
end

