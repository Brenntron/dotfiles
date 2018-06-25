class Dispute < ApplicationRecord
  has_paper_trail on: [:update], ignore: [:updated_at]
  has_many :dispute_comments
  has_many :dispute_emails
  has_many :dispute_entries
  belongs_to :customer

  def is_assigned?
    (!self.assigned_to.nil? and !self.assigned_to.empty?)
  end

  def assignee
    is_assigned? ? assigned_to : "Unassigned"
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

  def dispute_age
    age = case_opened_at - DateTime.now
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

  def compose_versioned_items
    versioned_items = [self]

    dispute_comments.map{ |dc| versioned_items << dc}
    dispute_entries.map{ |de| versioned_items << de}

    versioned_items
  end

  def self.process_bridge_payload(message_payload)
    user = User.where(cvs_username:"vrtincom").first
    #TODO: this should be put in a params method
    message_payload["payload"] = message_payload["payload"].permit!.to_h
    new_entries_ips = message_payload["payload"]["investigate_ips"].permit!.to_h
    new_entries_urls = message_payload["payload"]["investigate_urls"].permit!.to_h

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
    new_dispute.id = bug_stub_hash["id"]
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
    new_dispute.save

    new_entries_ips.each do |key, entry|
      new_dispute_entry = DisputeEntry.new
      new_dispute_entry.dispute_id = new_dispute.id
      new_dispute_entry.ip_address = key
      new_dispute_entry.entry_type = "IP"
      new_dispute_entry.score_type = "SBRS"
      new_dispute_entry.score = entry["SBRS_SCORE"].to_f
      new_dispute_entry.suggested_disposition = entry["reg_sugg"]
      new_dispute_entry.save

      if entry["SBRS_Rule_Hits"].present?
        all_hits = entry["SBRS_Rule_Hits"].split(",")
        all_hits.each do |rule_hit|
          new_rule_hit = DisputeRuleHit.new
          new_rule_hit.dispute_entry_id = new_dispute_entry.id
          new_rule_hit.name = rule_hit.strip
          new_rule_hit.save
        end
      end

    end

    new_entries_urls.each do |entry|

      new_dispute_entry = DisputeEntry.new
      new_dispute_entry.dispute_id = new_dispute.id
      new_dispute_entry.ip_address = key
      new_dispute_entry.entry_type = "DOMAIN"
      new_dispute_entry.score_type = "WBRS"
      new_dispute_entry.score = entry["WBRS_SCORE"].to_f
      new_dispute_entry.suggested_disposition = entry["reg_sugg"]
      new_dispute_entry.save

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

    #change this
    return_message = {
      "envelope":
          {
              "channel": "ticket-acknowledge",
              "addressee": "talos-intelligence",
              "sender": "analyst-console"
          },
      "message": {"source_key":params["source_key"],"ac_status":"CREATE_ACK"}
    }
  end

  # Searches based on supplied fields and values.
  # Optionally takes a name to save this search as a saved search.
  # @param [ActionController::Parameters] params supplied fields and values for search.
  # @param [String] search_name name to save this search as a saved search.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.advanced_search(params, search_name:, user:)
    raise 'Search must use ActionController::Parameters!' unless params.kind_of?(ActionController::Parameters)
    raise 'Cannot search with unpermitted parameters!' unless params.permitted?

    present_params = params.select{ |key, value| value.present? }

    # Save this search as a named search
    if present_params.present? && search_name.present?
      named_search =
          user.named_searches.where(name: search_name).first || NamedSearch.create!(user: user, name: search_name)
      NamedSearchCriterion.where(named_search: named_search).delete_all
      present_params.each do |field_name, value|
        named_search.named_search_criteria.create(field_name: field_name, value: value)
      end
    end

    where(present_params)
  end

  # Searched based on saved search.
  # @param [String] search_name the name of the saved search.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.named_search(search_name, user:)
    named_search = user.named_searches.where(name: search_name).first
    raise "No search named '#{search_name}' found." unless named_search
    search_params = named_search.named_search_criteria.inject({}) do |search_params, criterion|
      search_params[criterion.field_name] = criterion.value
      search_params
    end
    where(search_params)
  end

  # Searches based on standard pre-determined filters.
  # @param [String] search_name name of the filter.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.standard_search(search_name)
    case search_name
      when 'Open'
        where(status: 'Open')
      when 'Closed'
        where(status: 'Closed')
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
  def self.robust_search(search_type, params: nil, search_name: nil, user:)
    case search_type
      when 'advanced'
        advanced_search(params, search_name: search_name, user: user)
      when 'named'
        named_search(search_name, user: user)
      when 'standard'
        standard_search(search_name)
      when 'contains'
        contains_search(params['value'])
      else
        where({})
    end
  end
end

