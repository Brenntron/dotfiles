include ActionView::Helpers::DateHelper

class Dispute < ApplicationRecord
  has_paper_trail on: [:update], ignore: [:updated_at]

  belongs_to :customer
  belongs_to :user, :optional => true
  belongs_to :related_dispute, class_name: 'Dispute', foreign_key: :related_id, required: false
  belongs_to :platform, :optional => true
  has_many :relating_disputes, class_name: 'Dispute', foreign_key: :related_id, dependent: :nullify
  has_many :dispute_comments, dependent: :destroy
  has_many :dispute_emails, dependent: :destroy
  has_many :dispute_entries, dependent: :restrict_with_exception
  has_many :dispute_peeks, -> { order("dispute_peeks.updated_at desc") }, dependent: :destroy
  has_many :recent_dispute_views, class_name: 'User', through: :dispute_peeks, source: :user

  delegate :cvs_username, to: :user, allow_nil: true

  NEW = 'NEW'
  RESOLVED = 'RESOLVED_CLOSED'
  ASSIGNED = 'ASSIGNED'
  CLOSED = 'CLOSED'
  DUPLICATE = 'DUPLICATE'

  ANALYST_COMPLETED = "Analyst Completed"
  ALL_AUTO_RESOLVED = "All Auto Resolved"

  TI_NEW = 'PENDING'
  TI_RESOLVED = 'RESOLVED'
  TI_CLOSED = 'CLOSED'

  AC_SUCCESS = 'CREATE_ACK'
  AC_FAILED = 'CREATE_FAILED'
  AC_PENDING = 'CREATE_PENDING'

  SUBMITTER_TYPE_CUSTOMER = "CUSTOMER"
  SUBMITTER_TYPE_NONCUSTOMER = "NON-CUSTOMER"

  PRIORITY_1 = 'P1'
  PRIORITY_2 = 'P2'
  PRIORITY_3 = 'P3'
  PRIORITY_4 = 'P4'
  PRIORITY_5 = 'P5'

  # It's possible that some of this is duplicates of the above but I'm too scared to try and consolidate
  # them. These strings apply specifically to the "Status" dropdown on **Disputes**. To edit these strings
  # for a **DisputeEntry**, see `models/dispute_entry.rb`
  STATUS_NEW = "NEW"
  STATUS_RESEARCHING = "RESEARCHING"
  STATUS_ESCALATED = "ESCALATED"
  STATUS_CUSTOMER_PENDING = "CUSTOMER_PENDING"
  STATUS_CUSTOMER_UPDATE = "CUSTOMER_UPDATE"
  STATUS_ON_HOLD = "ON_HOLD"
  STATUS_RESOLVED = "RESOLVED_CLOSED"
  STATUS_ASSIGNED = "ASSIGNED"
  STATUS_REOPENED = "RE-OPENED"

  STATUS_RESOLVED_FIXED_FP = "FIXED_FP"
  STATUS_RESOLVED_FIXED_FN = "FIXED_FN"
  STATUS_RESOLVED_UNCHANGED = "UNCHANGED"
  STATUS_RESOLVED_INVALID = "INVALID"
  STATUS_RESOLVED_TEST = "TEST_TRAINING"
  STATUS_RESOLVED_OTHER = "OTHER"
  STATUS_RESOLVED_QUICK_BULK = "QUICK_BULK" #tickets created and closed using the quick bulk entry form.

  #AUTORESOLVED_UNCHANGED_MESSAGE = "The Talos web reputation will remain unchanged, based on available information. If you have further information regarding this URL/Domain/Host that indicates its involvement in malicious activity, please use the Email Support Regarding this Ticket link to send it to us for review."
  AUTORESOLVED_UNCHANGED_MESSAGE = "Talos has not found sufficient evidence to modify the current reputation of the submission; we cannot change the submission's reputation because it can negatively affect our customers. However, a customer has the option of locally changing a submission's reputation, if they understand the risks in doing so. Please open a TAC case and provide additional details if you need further assistance."


  #labels for charts on webrep dashboard
  LABEL_RESOLVED_FIXED_FP = "Fixed FP"
  LABEL_RESOLVED_FIXED_FN = "Fixed FN"
  LABEL_RESOLVED_UNCHANGED = "Unchanged"
  LABEL_RESOLVED_OTHER = "Other"

  TICKET_CONVERSION_CUSTOMER_MESSAGE = "Thank you for your request; this has now been forwarded to the team responsible for Web categorization requests. A new Web categorization ticket has been created on your behalf and should be visible in your ticket submission queue. Please see all updates regarding this request on the new ticket.

For future Web categorization requests, please open a Web categorization ticket using the \"Web Categorization Requests\" form: https://talosintelligence.com/reputation_center/support#reputation_center_support_ticket"

  AUTO_TICKET_CONVERSION_CUSTOMER_MESSAGE = "Thank you for your request; this has now been forwarded to the team responsible for Web categorization requests. A new Web categorization ticket has been created on your behalf and should be visible in your ticket submission queue. Please see all updates regarding this request on the new ticket.

Please note that by default, a submission with a Trusted, Favorable, Neutral, or Questionable reputation should be accessible by our customers. Talos does not improve the reputation of already accessible submissions as this would affect the way our automated system functions. If one of our customers cannot access the submission after successful web categorization, that is due to aggressive settings on their side and can only be fixed locally by that customer. If you would like this to be reviewed further, please open a TAC case.

For future Web categorization requests, please open a Web categorization ticket using the \"Web Categorization Requests\" form: https://talosintelligence.com/reputation_center/support#reputation_center_support_ticket"


  AUTO_NC_TICKET_CONVERSION_CUSTOMER_MESSAGE = "Thank you for your request; this has now been forwarded to the team responsible for Web categorization requests. A new Web categorization ticket has been created on your behalf and should be visible in your ticket submission queue. Please see all updates regarding this request on the new ticket.

Please note that by default, a submission with a Trusted, Favorable, Neutral, or Questionable reputation should be accessible by our customers. Talos does not improve the reputation of already accessible submissions as this would affect the way our automated system functions. If one of our customers cannot access the submission after successful web categorization, that is due to aggressive settings on their side and can only be fixed locally by that customer.

For future Web categorization requests, please open a Web categorization ticket using the \"Web Categorization Requests\" form: https://talosintelligence.com/reputation_center/support#reputation_center_support_ticket"

  scope :open_disputes, -> { where(status: NEW) }
  scope :assigned_disputes, -> { where(status: STATUS_ASSIGNED) }
  scope :closed_disputes, -> { where(status: RESOLVED) }
  scope :in_progress_disputes, -> { where(status: [ STATUS_RESEARCHING, STATUS_ESCALATED, STATUS_CUSTOMER_PENDING, STATUS_ON_HOLD, STATUS_REOPENED, STATUS_CUSTOMER_UPDATE ]) }
  scope :my_team, ->(user) { where(user_id: user.my_team) }
  scope :sbrs_disputes, -> { where(submission_type: ['e', 'ew'])}
  scope :wbrs_disputes, -> { where(submission_type: ['w', 'ew'])}

  validates_length_of :resolution_comment, maximum: 2000, allow_blank: true

  validates_with DisputeValidator

  def self.create_action(bugzilla_rest_session, ips_urls, assignee, priority, ticket_type, status=NEW, categories = nil)
    user = User.where(cvs_username: assignee).first

    case ticket_type
    when 'Web'
      ticket_type = 'w'
    when 'Email'
      ticket_type = 'e'
    when 'Email & Web'
      ticket_type = 'ew'
    end

    customer = Customer.where(name: 'Dispute Analyst').first_or_create(name: 'Dispute Analyst')

    summary = "New WebRep Dispute generated at #{DateTime.now.utc.strftime("%Y-%m-%d %H:%M")}"

    # Does a description need to go in here and be in the form?
    full_description = %Q{
          IPs/URIs: #{ips_urls}
    }

    bug_attrs = {
        'product' => 'Escalations Console',
        'component' => 'IP/Domain',
        'summary' => summary,
        'version' => 'unspecified',
        'description' => full_description,
        'priority' => priority,
        'classification' => 'unclassified',
    }
    new_dispute = nil

    bug_proxy = bugzilla_rest_session.create_bug(bug_attrs)
    ActiveRecord::Base.transaction do
      new_dispute = Dispute.create!(id: bug_proxy.id,
                                       user_id: user.id,
                                       priority: priority,
                                       submission_type: ticket_type,
                                       submitter_type: 'Internal',
                                       status: status,
                                       customer_id: customer.id,
                                       case_opened_at: Time.now)
      ips_urls.each do |ip_url|
        if DisputeEntry.check_for_duplicates(ip_url) == false
          DisputeEntry.create_dispute_entry(new_dispute, ip_url, status)
        end
      end
    end

    new_dispute
  end

  def case_id_str
    '%010i' % id
  end

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

  def last_updated_by
    if versions.any?
      who = versions.last&.whodunnit
      who && User.find(who)
    else
      nil
    end
  end

  def last_updated_by_username
    last_updated_by&.cvs_username
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
    elsif hh == 0
      "<1 hr"
    end
  end

  def minutes_to_accept
    if case_accepted_at && case_opened_at
      (case_accepted_at - case_opened_at) / 60.0
    end
  end

  def minutes_to_respond
    if case_responded_at && case_opened_at
      (case_responded_at - case_opened_at) / 60.0
    end
  end

  def minutes_to_close
    if case_closed_at && case_opened_at
      (case_closed_at - case_opened_at) / 60.0
    end
  end

  def days_to_close
    minutes_to_close && minutes_to_close / 1440.0
  end

  def each_duplicate(&block)
    if related_dispute
      #block.call(related_dispute)
      related_dispute.relating_disputes.where(resolution: Dispute::DUPLICATE).where.not(id: self.id).each(&block)
    else
      relating_disputes.where(resolution: Dispute::DUPLICATE).where.not(id: self.id).each(&block)
    end
  end

  def each_related(&block)
    if related_dispute && Dispute::DUPLICATE != self.resolution
      block.call(related_dispute)
      related_dispute.relating_disputes.where.not(resolution: Dispute::DUPLICATE).each(&block)
    else
      relating_disputes.each(&block)
    end
  end

  def full_duplicates
    result = []
    each_duplicate do |other_dispute|
      result << other_dispute
    end
    result
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

  def self.is_possible_customer_duplicate?(dispute, new_entries_ips, new_entries_urls)

    new_uris = new_entries_urls.keys.sort
    new_ips = new_entries_ips.keys.sort

    response = {}
    possibles = Dispute.includes(:dispute_entries).where(:customer_id => dispute.customer_id).select {|dispute| dispute.status != RESOLVED || dispute.status != DUPLICATE}
    candidates = []

    all_resolved = true

    # If all possible Disputes are Resolved or Duplicate, do not register as a duplicate
    possibles.each do |poss|

      ips = poss.dispute_entries.select{ |entry| entry.entry_type == "IP"}.pluck(:ip_address).sort
      uris = poss.dispute_entries.select{ |entry| entry.entry_type == "URI/DOMAIN"}.pluck(:uri).sort

      if ips == new_ips && uris == new_uris
        candidates << poss
      end
    end

    if candidates.find{ |candidate| candidate.status != RESOLVED }
      all_resolved = false
    end

    if candidates.any?
      best_candidate = candidates.sort_by {|candidate| candidate.id}.first
      response[:authority] = best_candidate
      response[:is_dupe] = true
      response[:all_resolved] = all_resolved
    else
      response[:is_dupe] = false
    end

    response

  end

  def self.manage_all_resolved_duplicate_dispute(dispute, authority_dispute)
    dispute.related_id = authority_dispute.id
    dispute.related_at = Time.now
    dispute.save!
  end

  def self.manage_duplicate_dispute(dispute, authority_dispute, new_entries_ips, new_entries_urls, source_key)
    resolved_at = Time.now
    dispute.status = Dispute::RESOLVED
    dispute.related_id = authority_dispute.id unless authority_dispute.blank?
    dispute.related_at = Time.now
    dispute.resolution = Dispute::DUPLICATE
    dispute.case_closed_at = Time.now
    dispute.case_resolved_at = Time.now
    dispute.save

    return_payload = {}

    new_entries_ips.each do |ip, entry|
      new_payload_item = {}
      new_payload_item[:resolution_message] = "This is a duplicate of a currently active ticket."
      new_payload_item[:resolution] = "DUPLICATE"
      new_payload_item[:status] = TI_RESOLVED
      new_payload_item[:sugg_type] = entry[:sbrs]["rep_sugg"]
      return_payload[ip] = new_payload_item
      new_dispute_entry = DisputeEntry.new
      new_dispute_entry.dispute_id = dispute.id
      new_dispute_entry.ip_address = ip
      new_dispute_entry.entry_type = "IP"
      new_dispute_entry.status = DisputeEntry::STATUS_RESOLVED
      new_dispute_entry.resolution = DisputeEntry::STATUS_AUTO_RESOLVED_DUPLICATE
      new_dispute_entry.suggested_disposition = entry[:sbrs]["rep_sugg"]
      new_dispute_entry.case_closed_at = resolved_at
      new_dispute_entry.case_resolved_at = resolved_at
      new_dispute_entry.save
    end
    new_entries_urls.each do |url, entry|
      new_payload_item = {}
      new_payload_item[:resolution_message] = "This is a duplicate of a currently active ticket."
      new_payload_item[:resolution] = "DUPLICATE"
      new_payload_item[:status] = TI_RESOLVED
      new_payload_item[:sugg_type] = entry["rep_sugg"]
      return_payload[url] = new_payload_item
      new_dispute_entry = DisputeEntry.new
      new_dispute_entry.dispute_id = dispute.id
      new_dispute_entry.uri = url
      new_dispute_entry.entry_type = "URI/DOMAIN"
      new_dispute_entry.suggested_disposition = entry["rep_sugg"]
      new_dispute_entry.status = DisputeEntry::STATUS_RESOLVED
      new_dispute_entry.resolution = DisputeEntry::STATUS_AUTO_RESOLVED_DUPLICATE
      new_dispute_entry.case_closed_at = resolved_at
      new_dispute_entry.case_resolved_at = resolved_at
      new_dispute_entry.save
    end

    conn = ::Bridge::DisputeCreatedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: source_key, ac_id: dispute.id, status: dispute.reload.status)
    conn.post(return_payload, "")

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
      if entry.status != DisputeEntry::STATUS_RESOLVED
        is_resolved = false
        break
      end
    end

    if is_resolved == true
      resolved_at = Time.now
      self.status = Dispute::RESOLVED
      self.resolution = new_resolution
      self.case_closed_at = resolved_at
      self.case_resolved_at = resolved_at
      save!
    end
  end

  #TODO: REFACTOR TO MAKE PROCESS_BRIDGE_PAYLOAD A SMALLER METHOD
  #These are instance methods used in building out the full dispute in a thread fired from self.process_bridge_payload
  #


  def self.is_important?(key)
    top_url = Wbrs::TopUrl.check_urls([key]).first
    return false if 'invalid' == top_url.is_important
    top_url.is_important
  rescue => except

    Rails.logger.warn "Processing bridge payload failed checking WBRS for is_important"
    Rails.logger.warn except
    Rails.logger.warn except.backtrace.join("\n")

    nil
  end


  def build_ti_payload
    payload = {}

    dispute_entries.each do |entry|
      payload[entry.hostlookup] = entry.new_payload_item
      payload[entry.hostlookup]['sugg_type'] = entry.suggested_disposition
    end

    payload
  end

  #
  #end dispute building instance methods
  #

  ################REBUILD A DISPUTE FROM A PACKET#########################

  def rebuild_from_packet()

    results = {}
    results[:errors] = []
    results[:status] = nil
    results[:messages] = []

    if self.bridge_packet.blank?
      results[:errors] << "bridge packet is empty."
      results[:status] = "error"
      return results
    end

    message_payload = JSON.parse(self.bridge_packet)

    new_entries_ips = message_payload["payload"]["investigate_ips"]
    new_entries_urls = message_payload["payload"]["investigate_urls"]

    attempted_entries = []
    attempted_entries += new_entries_ips.keys
    attempted_entries += new_entries_urls.keys

    results[:messages] << "entries attempted: #{attempted_entries.join(",")}"

    if self.dispute_entries.present?
      results[:errors] << "dispute is not empty, cannot attempt rebuild."
      results[:status] = "error"
      return results
    end

    begin
      response = Dispute.build_new_entries(self, new_entries_ips, new_entries_urls)
    rescue => e
      Rails.logger.error e
      Rails.logger.error e.backtrace.join("\n")
      results[:status] = "error"
      results[:errors] << "An error occurred attempting to build new entries."
      return results
    end

    self.reload

    if response[:status] == "success"
      begin
        Dispute.auto_resolve_entries(self, response[:entry_claims])
      rescue => e
        Rails.logger.error e
        Rails.logger.error e.backtrace.join("\n")
        results[:messages] << "attempting to auto resolve failed."
      end
    end

    return results

  end

  #########
  # TODO: eventually these following methods should be used in project refactor to make process bridge payload even more efficient

  def self.auto_resolve_entries(dispute, entry_claims)

    ######AUTO RESOLVE LOGIC########
    begin
      umbrella_no_reply = Platform.find_by_all_names("Umbrella - No Reply")

      dispute.dispute_entries.each do |dispute_entry|
        false_negative_claim = false
        matching_disposition = false
        entry_claim = entry_claims[dispute_entry.hostlookup]

        if dispute.determine_platform.present? && dispute.determine_platform.downcase.include?("umbrella")
          matching_disposition = dispute_entry.is_disposition_matching?(entry_claim, true)
        else
          matching_disposition = dispute_entry.is_disposition_matching?(entry_claim)
        end
        initial_log = "--------Starting Data---------<br>"
        initial_log += "suggested disposition: #{dispute_entry.suggested_disposition}<br>"
        initial_log += "effective disposition info: #{dispute_entry.running_verdict.inspect.to_s}<br>"
        initial_log += "-----------------------------<br>"

        dispute_entry.auto_resolve_log += initial_log
        dispute_entry.save!

        ########Auto Resolve for IP addressses (email)##############
        if dispute_entry.entry_type == "IP"

          logger.info "fetching preload"

          begin
            ::Preloader::Base.fetch_all_api_data(dispute_entry.hostlookup, dispute_entry.id)
          rescue => e
            Rails.logger.error e
            Rails.logger.error e.backtrace.join("\n")
          end

          if !matching_disposition

            if entry_claim != "false negative"
              dispute_entry.status = DisputeEntry::NEW

              if dispute_entry.determine_platform_record.present? && dispute_entry.determine_platform_record.id == umbrella_no_reply.id
                AutoResolve.auto_resolve_umbrella_false_positive(dispute_entry)
                dispute_entry.reload
              else
                if dispute.submitter_type == "NON-CUSTOMER" && dispute.submission_type == "e"
                  AutoResolve.auto_resolve_email(dispute_entry, dispute_entry.dispute_rule_hits.pluck(:name))
                  dispute_entry.reload
                end
              end
            else
              if dispute.submission_type == "w"
                if dispute_entry.determine_platform_record.present? && dispute_entry.determine_platform_record.id == umbrella_no_reply.id
                  dispute_entry = AutoResolve.attempt_ai_conviction(dispute_entry.dispute_rule_hits.pluck(:name), dispute_entry, true)
                else
                  dispute_entry = AutoResolve.attempt_ai_conviction(dispute_entry.dispute_rule_hits.pluck(:name), dispute_entry)
                end
              end
              dispute_entry.save
            end

          end
          return_payload[dispute_entry.hostlookup] = dispute_entry.new_payload_item
          return_payload[dispute_entry.hostlookup]['sugg_type'] = dispute_entry.suggested_disposition

        end

        ############################################################
        #########Auto Resolve for URLs (web)########################
        if dispute_entry.entry_type == "URI/DOMAIN"

          logger.info "fetching preload"

          begin
            ::Preloader::Base.fetch_all_api_data(dispute_entry.hostlookup, dispute_entry.id)
          rescue => e
            Rails.logger.error e
            Rails.logger.error e.backtrace.join("\n")
          end

          #threat cats for urls
          begin
            complete_wbrs_blob = Wbrs::ManualWlbl.where({:url => dispute_entry.uri})
            dispute_entry.wbrs_threat_category = [complete_wbrs_blob.last].select{ |wlbl| wlbl&.state == "active"}.map{ |wlbl| wlbl.threat_cats }.join(', ')
          rescue => e
            Rails.logger.error e
            Rails.logger.error e.backtrace.join("\n")
          end

          begin
            dispute_entry.is_important = is_important?(dispute_entry.hostlookup)
          rescue => e
            Rails.logger.error e
            Rails.logger.error e.backtrace.join("\n")
          end

          begin
            if dispute_entry.web_ips.present?

              web_ips_formatted = dispute_entry.web_ips.gsub("[", "").gsub("]", "").gsub("\"", "").split(", ")

              extra_wbrs_stuff = Sbrs::Base.combo_call_sds_v3(dispute_entry.uri, web_ips_formatted)
              extra_wbrs_stuff_rulehits = Sbrs::ManualSbrs.get_rule_names_from_rulehits(extra_wbrs_stuff) rescue []

              if extra_wbrs_stuff.present?
                dispute_entry.score = extra_wbrs_stuff["wbrs"]["score"]

                threat_cats = extra_wbrs_stuff["threat_cats"]

                threat_cat_names = []
                if threat_cats.present?
                  threat_cat_info = DisputeEntry.threat_cats_from_ids(threat_cats)
                  threat_cat_info.each do |name|
                    threat_cat_names << name[:name]
                  end
                  dispute_entry.multi_wbrs_threat_category = threat_cat_names
                end
              end


              extra_wbrs_stuff_rulehits.each do |rule_hit|
                new_rule_hit = DisputeRuleHit.new
                new_rule_hit.name = rule_hit.strip
                new_rule_hit.rule_type = "WBRS"
                new_rule_hit.is_multi_ip_rulehit = true
                dispute_entry.dispute_rule_hits << new_rule_hit
              end
            end
          rescue => e
            Rails.logger.error e
            Rails.logger.error e.backtrace.join("\n")
          end


          dispute_entry.save!

          if !matching_disposition

            if entry_claim != "false negative"

              if dispute_entry.determine_platform_record.present? && dispute_entry.determine_platform_record.id == umbrella_no_reply.id
                AutoResolve.auto_resolve_umbrella_false_positive(dispute_entry)
                dispute_entry.reload
              else
                dispute_entry.update(status: DisputeEntry::NEW)
              end
            else

              if dispute_entry.determine_platform_record.present? && dispute_entry.determine_platform_record.id == umbrella_no_reply.id

                dispute_entry = AutoResolve.attempt_ai_conviction(dispute_entry.dispute_rule_hits.pluck(:name), dispute_entry, true)
              else
                dispute_entry = AutoResolve.attempt_ai_conviction(dispute_entry.dispute_rule_hits.pluck(:name), dispute_entry)
              end
            end
            dispute_entry.save
          end

          return_payload[dispute_entry.hostlookup] = dispute_entry.new_payload_item
          return_payload[dispute_entry.hostlookup]['sugg_type'] = dispute_entry.suggested_disposition
        end

      end
    rescue Exception => e

      Rails.logger.error e
      Rails.logger.error e.backtrace.join("\n")
    end

  end


  def self.build_new_entries(dispute, new_entries_ips, new_entries_urls)
    response = {}
    response[:errors] = []
    response[:status] = nil
    response[:entry_claims] = nil
    entry_claims = {}

    opened_at = dispute.case_opened_at

    new_entries_ips.each do |ip, entry|


      #if ["Suspicious sites", "High risk","Poor"].include?(entry[:sbrs]["rep_sugg"])
      #  false_negative_claim = true
      #end
      #
      claim = entry["sbrs"]["claim"]
      entry_claims[ip] = claim

      if entry["sbrs"]["platform"].present?
        entry_platform = Platform.find(entry[:sbrs]["platform"].to_i) rescue nil
      end

      new_dispute_entry = DisputeEntry.new
      new_dispute_entry.auto_resolve_log = ""
      new_dispute_entry.case_opened_at = opened_at
      new_dispute_entry.dispute_id = dispute.id
      new_dispute_entry.ip_address = ip
      new_dispute_entry.entry_type = "IP"
      new_dispute_entry.status = DisputeEntry::NEW
      new_dispute_entry.resolution = ""
      new_dispute_entry.suggested_disposition = entry["sbrs"]["rep_sugg"]
      new_dispute_entry.suggested_threat_category = entry["sbrs"]["suggested_threat_category"] unless entry["sbrs"]["suggested_threat_category"].blank?

      new_dispute_entry.sbrs_score = entry["sbrs"]["SBRS_SCORE"] == "No score" ? nil : entry["sbrs"]["SBRS_SCORE"]
      new_dispute_entry.wbrs_score = entry["wbrs"]["WBRS_SCORE"] == "No score" ? nil : entry["wbrs"]["WBRS_SCORE"]
      new_dispute_entry.suggested_disposition = entry["sbrs"]["rep_sugg"]
      new_dispute_entry.platform_id = entry_platform.id unless entry_platform.blank?
      new_dispute_entry.platform = entry["sbrs"]["platform"] if (entry["sbrs"]["platform"].present? && !entry["sbrs"]["platform"].kind_of?(Integer))
      new_dispute_entry.save!

      if entry && entry["wbrs"] && entry["wbrs"]["WBRS_Rule_Hits"]
        wbrs_hits = entry["wbrs"]["WBRS_Rule_Hits"].split(",").map {|hit| hit.strip }
      else
        Rails.logger.error('No data for WBRS Rule Hits')
        wbrs_hits = []
      end

      if entry && entry["sbrs"] && entry["sbrs"]["SBRS_Rule_Hits"]
        sbrs_hits = entry["sbrs"]["SBRS_Rule_Hits"].split(",").map {|hit| hit.strip }
      else
        Rails.logger.error('No data for SBRS Rule Hits')
        sbrs_hits = []
      end

      #total_hits = (wbrs_hits + sbrs_hits).uniq


      sbrs_hits.each do |rule_hit|
        new_rule_hit = DisputeRuleHit.new
        new_rule_hit.dispute_entry_id = new_dispute_entry.id
        new_rule_hit.name = rule_hit.strip
        new_rule_hit.rule_type = "SBRS"
        new_rule_hit.save!
      end

      wbrs_hits.each do |rule_hit|
        new_rule_hit = DisputeRuleHit.new
        new_rule_hit.dispute_entry_id = new_dispute_entry.id
        new_rule_hit.name = rule_hit.strip
        new_rule_hit.rule_type = "WBRS"
        new_rule_hit.save!
      end

    end

    new_entries_urls.each do |url, entry|

      claim = entry["claim"]
      entry_claims[url] = claim

      if entry["platform"].present?
        entry_platform = Platform.find(entry["platform"].to_i) rescue nil
      end

      new_dispute_entry = DisputeEntry.new
      new_dispute_entry.dispute_id = dispute.id
      new_dispute_entry.uri = url
      new_dispute_entry.entry_type = "URI/DOMAIN"
      new_dispute_entry.suggested_disposition = entry["rep_sugg"]
      new_dispute_entry.status = DisputeEntry::NEW
      new_dispute_entry.resolution = ""
      new_dispute_entry.suggested_threat_category = entry["suggested_threat_category"] unless entry["suggested_threat_category"].blank?
      new_dispute_entry.case_opened_at = opened_at
      new_dispute_entry.wbrs_score = entry["WBRS_SCORE"] == "No score" ? nil : entry["WBRS_SCORE"]

      resolved_ip = Resolv.getaddress(DisputeEntry.domain_of(new_dispute_entry.uri)) rescue nil
      if resolved_ip.present?
        new_dispute_entry.web_ips = [resolved_ip]
      end


      #new_dispute_entry.is_important = is_important?(key)
      new_dispute_entry.auto_resolve_log = ""
      begin
        new_dispute_entry.assign_url_parts(url)
      rescue => e
        Rails.logger.error e
        Rails.logger.error e.backtrace.join("\n")
      end
      new_dispute_entry.platform = entry["platform"] if (entry["platform"].present? && !entry["platform"].kind_of?(Integer))
      new_dispute_entry.platform_id = entry_platform.id unless entry_platform.blank?


      new_dispute_entry.save

      if entry["WBRS_Rule_Hits"].present?
        all_hits = entry["WBRS_Rule_Hits"].split(",")
        all_hits.each do |rule_hit|
          new_rule_hit = DisputeRuleHit.new
          new_rule_hit.dispute_entry_id = new_dispute_entry.id
          new_rule_hit.name = rule_hit.strip
          new_rule_hit.rule_type = "WBRS"
          new_rule_hit.save!
        end
      end

    end

    response[:entry_claims] = entry_claims
    response

  end

  ##############END DISPUTE REBUILD#################################

  def self.sanitize_url(url)
    original_url = url

    begin
      if url.first(3).downcase == "ftp"
        url = url.gsub("ftp://", '')
      end

      sanitized_url = ""

      if url.first(4).downcase != "http"
        url = "http://" + url
      end

      url_parts = Complaint.parse_url(url)

      if url_parts[:subdomain].present?
        sanitized_url += url_parts[:subdomain] + "."
      end
      sanitized_url += url_parts[:domain] + url_parts[:path]
      if url_parts[:query].present?
        sanitized_url += "?" + url_parts[:query]
      end

      if sanitized_url.blank?
        sanitized_url = original_url
      end

      URI.decode(sanitized_url)
    rescue
      return original_url
    end

  end

  def self.process_bridge_payload(message_payload)

    #check to see if ticket already exists in database to prevent accidental dupes
    record_exists = Dispute.where(:ticket_source_key => message_payload["source_key"]).first

    if record_exists.present?
      conn = ::Bridge::DisputeCreatedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: message_payload["source_key"], ac_id: record_exists.id, status: record_exists.status)
      return_payload = record_exists.build_ti_payload
      case_email = DisputeEmail.generate_case_email_address(record_exists.id)
      return conn.post(return_payload, case_email)

    end

    new_dispute = nil
    verdicts_to_blacklist = []
    user = User.where(cvs_username:"vrtincom").first

    begin

      entry_claims = {}

      guest = Company.where(:name => "Guest").first
      opened_at = Time.now
      resolved_at = Time.now
      customer = Customer.process_and_get_customer(message_payload)


      logger.debug "Starting ticket create"

      #user = User.where(cvs_username:"vrtincom").first

      #TODO: this should be put in a params method
      new_entries_ips = message_payload["payload"]["investigate_ips"]
      new_entries_urls = message_payload["payload"]["investigate_urls"]

      return_payload = {}

      #create an escalations IP/DOMAIN bugzilla bug here and transfer id to new dispute

      bugzilla_rest_session = message_payload[:bugzilla_rest_session]

      summary = "New Web Reputation Dispute generated at #{DateTime.now.utc.strftime("%Y-%m-%d %H:%M")}"

      full_description = <<~HEREDOC
        IPs: #{new_entries_ips.keys}
        URIs: #{new_entries_urls.keys}
        Problem Summary: #{message_payload["payload"]["problem"]}
        HEREDOC

      bug_attrs = {
          'product' => 'Escalations Console',
          'component' => 'IP/Domain',
          'summary' => summary,
          'version' => 'unspecified', #self.version,
          'description' => full_description,
          # 'opsys' => self.os,
          'priority' => 'Unspecified',
          'classification' => 'unclassified',
      }
      logger.debug "Creating bugzilla bug"

      bug_proxy = bugzilla_rest_session.create_bug(bug_attrs)

      if message_payload["payload"]["product_platform"].present?
        platform = Platform.find(message_payload["payload"]["product_platform"].to_i) rescue nil
      end
      logger.debug "Creating dispute"
      new_dispute = Dispute.new

      new_dispute.bridge_packet = message_payload.to_json


      new_dispute.id = bug_proxy.id
      new_dispute.meta_data = message_payload["payload"]["meta_data"]
      new_dispute.user_id = user.id
      new_dispute.source_ip_address = message_payload["payload"]["user_ip"]
      new_dispute.org_domain = message_payload["payload"]["domain"]
      new_dispute.case_opened_at = opened_at
      new_dispute.subject = message_payload["payload"]["email_subject"]
      new_dispute.description = message_payload["payload"]["email_body"]
      new_dispute.problem_summary = message_payload["payload"]["problem"]
      new_dispute.ticket_source_key = message_payload["source_key"]
      new_dispute.ticket_source = message_payload["source"].blank? ? "talos-intelligence" : message_payload["source"]
      new_dispute.ticket_source_type = message_payload["source_type"]
      new_dispute.platform_id = platform.id unless platform.blank?
      new_dispute.product_platform = message_payload["payload"]["product_platform"] unless (message_payload["payload"]["product_platform"].blank? || message_payload["payload"]["product_platform"].kind_of?(Integer))
      new_dispute.product_version = message_payload["payload"]["product_version"] unless message_payload["payload"]["product_version"].blank?
      new_dispute.in_network = message_payload["payload"]["network"] unless message_payload["payload"]["network"].blank?
      new_dispute.submission_type = message_payload["payload"]["submission_type"]  # email, web, both  [e|w|ew]
      new_dispute.status = NEW

      new_dispute.customer_id = customer&.id
      new_dispute.submitter_type = (new_dispute.customer.nil? || new_dispute.customer&.company_id == guest.id) ? SUBMITTER_TYPE_NONCUSTOMER : SUBMITTER_TYPE_CUSTOMER
      if message_payload["payload"]["api_customer"].present? && message_payload["payload"]["api_customer"] == true
        new_dispute.submitter_type = SUBMITTER_TYPE_CUSTOMER
      end


      if new_dispute.submitter_type == SUBMITTER_TYPE_CUSTOMER
        new_dispute.priority = "P3"
      else
        new_dispute.priority = "P4"
      end
      logger.debug "Saving Dispute"


      new_dispute.save!

      ##########################################################################################################

      ActiveRecord::Base.transaction do
        ##### create an IPS bug for this webrep entry if someone from tifpapi uses the network=true parameter
        if message_payload["payload"]["network"].present? && message_payload["payload"]["network"] == true
          ips_bug_proxy= build_ips_bug(bugzilla_rest_session, new_entries_ips, new_entries_urls, message_payload["payload"]["problem"], bug_proxy.id)
          linked_dispute_comment = DisputeComment.new
          linked_dispute_comment.dispute_id = new_dispute.id
          linked_dispute_comment.user_id = user.id
          linked_dispute_comment.comment = "Dispute is [in network], IPS bugzilla bug created. Reference Bugzilla ID: #{ips_bug_proxy.id}"
          linked_dispute_comment.save(:validate => false)

        end

        response = is_possible_customer_duplicate?(new_dispute, new_entries_ips, new_entries_urls)

        if response[:is_dupe] == true && response[:all_resolved] == false
          manage_duplicate_dispute(new_dispute, response[:authority], new_entries_ips, new_entries_urls, message_payload["source_key"] )
          return
        elsif response[:is_dupe] == true && response[:all_resolved] == true
          manage_all_resolved_duplicate_dispute(new_dispute, response[:authority])
        end

        new_entries_ips.each do |ip, entry|


          #if ["Suspicious sites", "High risk","Poor"].include?(entry[:sbrs]["rep_sugg"])
          #  false_negative_claim = true
          #end
          #
          claim = entry[:sbrs]["claim"]
          entry_claims[ip] = claim

          if entry[:sbrs]["platform"].present?
            entry_platform = Platform.find(entry[:sbrs]["platform"].to_i) rescue nil
          end

          new_dispute_entry = DisputeEntry.new
          new_dispute_entry.auto_resolve_log = ""
          new_dispute_entry.case_opened_at = opened_at
          new_dispute_entry.dispute_id = new_dispute.id
          new_dispute_entry.ip_address = ip
          new_dispute_entry.entry_type = "IP"
          new_dispute_entry.status = DisputeEntry::NEW
          new_dispute_entry.resolution = ""
          new_dispute_entry.suggested_disposition = entry[:sbrs]["rep_sugg"]
          new_dispute_entry.suggested_threat_category = entry[:sbrs]["suggested_threat_category"] unless entry[:sbrs]["suggested_threat_category"].blank?

          new_dispute_entry.sbrs_score = entry[:sbrs]["SBRS_SCORE"] == "No score" ? nil : entry[:sbrs]["SBRS_SCORE"]
          new_dispute_entry.wbrs_score = entry[:wbrs]["WBRS_SCORE"] == "No score" ? nil : entry[:wbrs]["WBRS_SCORE"]
          new_dispute_entry.suggested_disposition = entry[:sbrs]["rep_sugg"]
          new_dispute_entry.platform_id = entry_platform.id unless entry_platform.blank?
          new_dispute_entry.platform = entry[:sbrs]["platform"] if (entry[:sbrs]["platform"].present? && !entry[:sbrs]["platform"].kind_of?(Integer))
          new_dispute_entry.save!

          if entry && entry[:wbrs] && entry[:wbrs]["WBRS_Rule_Hits"]
            wbrs_hits = entry[:wbrs]["WBRS_Rule_Hits"].split(",").map {|hit| hit.strip }
          else
            Rails.logger.error('No data for WBRS Rule Hits')
            wbrs_hits = []
          end

          if entry && entry[:sbrs] && entry[:sbrs]["SBRS_Rule_Hits"]
            sbrs_hits = entry[:sbrs]["SBRS_Rule_Hits"].split(",").map {|hit| hit.strip }
          else
            Rails.logger.error('No data for SBRS Rule Hits')
            sbrs_hits = []
          end

          #total_hits = (wbrs_hits + sbrs_hits).uniq


          sbrs_hits.each do |rule_hit|
            new_rule_hit = DisputeRuleHit.new
            new_rule_hit.dispute_entry_id = new_dispute_entry.id
            new_rule_hit.name = rule_hit.strip
            new_rule_hit.rule_type = "SBRS"
            new_rule_hit.save!
          end

          wbrs_hits.each do |rule_hit|
            new_rule_hit = DisputeRuleHit.new
            new_rule_hit.dispute_entry_id = new_dispute_entry.id
            new_rule_hit.name = rule_hit.strip
            new_rule_hit.rule_type = "WBRS"
            new_rule_hit.save!
          end

        end

        new_entries_urls.each do |url, entry|

          claim = entry["claim"]
          entry_claims[url] = claim

          if entry["platform"].present?
            entry_platform = Platform.find(entry["platform"].to_i) rescue nil
          end

          sanitized_url = sanitize_url(url)

          new_dispute_entry = DisputeEntry.new
          new_dispute_entry.dispute_id = new_dispute.id
          new_dispute_entry.uri = sanitized_url
          new_dispute_entry.entry_type = "URI/DOMAIN"
          new_dispute_entry.suggested_disposition = entry["rep_sugg"]
          new_dispute_entry.status = DisputeEntry::NEW
          new_dispute_entry.resolution = ""
          new_dispute_entry.suggested_threat_category = entry["suggested_threat_category"] unless entry["suggested_threat_category"].blank?
          new_dispute_entry.case_opened_at = opened_at
          new_dispute_entry.wbrs_score = entry["WBRS_SCORE"] == "No score" ? nil : entry["WBRS_SCORE"]

          resolved_ip = Resolv.getaddress(DisputeEntry.domain_of(new_dispute_entry.uri)) rescue nil
          if resolved_ip.present?
            new_dispute_entry.web_ips = [resolved_ip]
          end


          #new_dispute_entry.is_important = is_important?(key)
          new_dispute_entry.auto_resolve_log = ""
          begin
            new_dispute_entry.assign_url_parts(sanitized_url)
          rescue => e
            Rails.logger.error e
            Rails.logger.error e.backtrace.join("\n")
          end
          new_dispute_entry.platform = entry["platform"] if (entry["platform"].present? && !entry["platform"].kind_of?(Integer))
          new_dispute_entry.platform_id = entry_platform.id unless entry_platform.blank?


          new_dispute_entry.save

          if entry["WBRS_Rule_Hits"].present?
            all_hits = entry["WBRS_Rule_Hits"].split(",")
            all_hits.each do |rule_hit|
              new_rule_hit = DisputeRuleHit.new
              new_rule_hit.dispute_entry_id = new_dispute_entry.id
              new_rule_hit.name = rule_hit.strip
              new_rule_hit.rule_type = "WBRS"
              new_rule_hit.save!
            end
          end

        end

        email_body = message_payload["payload"]["email_body"].to_s # Make sure we're working with a string
        email_body = email_body.truncate(64000, omission: '... THIS MESSAGE WAS LONGER THAN 64,000 CHARACTERS AND HAS BEEN TRUNCATED')
        first_email = DisputeEmail.new
        first_email.dispute_id = new_dispute.id
        first_email.email_headers = nil
        first_email.from = message_payload["payload"]["email"]
        first_email.to = nil
        first_email.subject = message_payload["payload"]["email_subject"]
        first_email.body = email_body
        first_email.status = DisputeEmail::UNREAD
        first_email.save!

      end

      new_dispute.dispute_entries.each do |dispute_entry|
        begin
          if dispute_entry.web_ips.present?

            web_ips_formatted = dispute_entry.web_ips.gsub("[", "").gsub("]", "").gsub("\"", "").split(", ")

            extra_wbrs_stuff = Sbrs::Base.combo_call_sds_v3(dispute_entry.uri, web_ips_formatted)
            extra_wbrs_stuff_rulehits = Sbrs::ManualSbrs.get_rule_names_from_rulehits(extra_wbrs_stuff) rescue []

            if extra_wbrs_stuff.present?
              dispute_entry.score = extra_wbrs_stuff["wbrs"]["score"]

              threat_cats = extra_wbrs_stuff["threat_cats"]

              threat_cat_names = []
              if threat_cats.present?
                threat_cat_info = DisputeEntry.threat_cats_from_ids(threat_cats)
                threat_cat_info.each do |name|
                  threat_cat_names << name[:name]
                end
                dispute_entry.multi_wbrs_threat_category = threat_cat_names
              end
            end


            extra_wbrs_stuff_rulehits.each do |rule_hit|
              new_rule_hit = DisputeRuleHit.new
              new_rule_hit.name = rule_hit.strip
              new_rule_hit.rule_type = "WBRS"
              new_rule_hit.is_multi_ip_rulehit = true
              dispute_entry.dispute_rule_hits << new_rule_hit
            end
          end
        rescue => e
          Rails.logger.error e
          Rails.logger.error e.backtrace.join("\n")
        end

        logger.info "fetching preload"

        begin
          ::Preloader::Base.fetch_all_api_data(dispute_entry.hostlookup, dispute_entry.id)
        rescue => e
          Rails.logger.error e
          Rails.logger.error e.backtrace.join("\n")
        end

        #threat cats for urls
        if dispute_entry.entry_type == "URI/DOMAIN"
          begin
            complete_wbrs_blob = Wbrs::ManualWlbl.where({:url => dispute_entry.uri})
            dispute_entry.wbrs_threat_category = [complete_wbrs_blob.last].select{ |wlbl| wlbl&.state == "active"}.map{ |wlbl| wlbl.threat_cats }.join(', ')
          rescue => e
            Rails.logger.error e
            Rails.logger.error e.backtrace.join("\n")
          end

          begin
            dispute_entry.is_important = is_important?(dispute_entry.hostlookup)
          rescue => e
            Rails.logger.error e
            Rails.logger.error e.backtrace.join("\n")
          end
        end
        dispute_entry.save!

      end

      ######record creation completed######

      ######AUTO RESOLVE LOGIC########
      begin
        #umbrella_no_reply = Platform.find_by_all_names("Umbrella - No Reply")

        new_dispute.dispute_entries.each do |dispute_entry|
          false_negative_claim = false
          matching_disposition = false
          entry_claim = entry_claims[dispute_entry.hostlookup]

          auto_resolve_params = {}
          auto_resolve_params[:entry_claim] = entry_claim
          auto_resolve_params[:dispute_entry] = dispute_entry

          initial_log = "--------Starting Data---------<br>"
          initial_log += "suggested disposition: #{dispute_entry.suggested_disposition}<br>"
          initial_log += "effective disposition info: #{dispute_entry.running_verdict.inspect.to_s}<br>"
          initial_log += "-----------------------------<br>"

          dispute_entry.auto_resolve_log += initial_log
          dispute_entry.save!
          begin
            AutoResolve.process_auto_resolution(auto_resolve_params)
          rescue Exception => e

            Rails.logger.error e
            Rails.logger.error e.backtrace.join("\n")
          end
          dispute_entry.save
          dispute_entry.reload
          return_payload[dispute_entry.hostlookup] = dispute_entry.new_payload_item
          return_payload[dispute_entry.hostlookup]['sugg_type'] = dispute_entry.suggested_disposition


        end
      rescue Exception => e

        Rails.logger.error e
        Rails.logger.error e.backtrace.join("\n")
      end

      new_dispute.reload
      new_dispute.check_entries_and_resolve(ALL_AUTO_RESOLVED)

      case_email = DisputeEmail.generate_case_email_address(new_dispute.id)
      Rails.logger.info "_+_+_+_+_+_+_+_+_Setting up Bridge post_+_+_+_+_+_+_+_+_"
      conn = ::Bridge::DisputeCreatedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: message_payload["source_key"], ac_id: new_dispute.id, status: new_dispute.status)
      Rails.logger.info "_+_+_+_+_+_+_+_+_Running Connection POST_+_+_+_+_+_+_+_+_"
      conn.post(return_payload, case_email)

      ##########################################################################################################

    rescue Exception => e

      if !message_payload["payload"]
        Rails.logger.error "Empty payload"
      end

      if !message_payload["payload"] || !message_payload["payload"]["investigate_ips"]
        Rails.logger.error "Empty IP payload"
      end

      if !message_payload["payload"] || !message_payload["payload"]["investigate_urls"]
        Rails.logger.error "Empty URL payload"
      end

      Rails.logger.error "Dispute failed to save, backing out all DB changes."
      Rails.logger.error $!
      Rails.logger.error $!.backtrace.join("\n")
      if new_dispute.present?
        new_dispute.reload
        new_dispute.dispute_entries.destroy_all
        new_dispute.destroy
      end
      if message_payload["source_key"].present?
        conn = ::Bridge::DisputeFailedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: message_payload["source_key"])
        conn.post
      end

      return nil
    end

    new_dispute.reload
    if new_dispute.dispute_entries.blank?
      new_dispute.dispute_entries.destroy_all
      new_dispute.destroy
      conn = ::Bridge::DisputeFailedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: message_payload["source_key"])
      conn.post
      return nil
    end

    new_dispute
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

  def self.save_named_search(search_name, params, user:, project_type:)
    NamedSearchCriterion.where(named_search_id: NamedSearch.where(user_id: user.id, name: search_name).ids).delete_all

    named_search =
        user.named_searches.where(name: search_name).first || NamedSearch.create!(user: user, name: search_name, project_type: project_type)

    params.each do |field_name, value|
      case
        when value.kind_of?(Hash)
          value.each do |sub_field_name, sub_value|
            named_search.named_search_criteria.create(field_name: "#{field_name}~#{sub_field_name}", value: sub_value)
          end
        when field_name == 'reload'
          #do nothing
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
  def self.advanced_search(params, search_name:, user:, reload: false)

    dispute_fields =
        params.to_h.slice(*%w{status org_domain priority resolution submitter_type
                              case_id case_owner_username})
    dispute_fields['id'] = dispute_fields.delete('case_id')

    if dispute_fields['priority'] && /(?<priority_digits>\d+)/ =~ dispute_fields.delete('priority')
      dispute_fields['priority'] = priority_digits
    end

    if dispute_fields['case_owner_username'].present?
      user = User.where(cvs_username: dispute_fields.delete('case_owner_username')).first
      dispute_fields['user_id'] = user.id
    end

    dispute_fields = dispute_fields.select{|ignore_key, value| value.present?}
    if dispute_fields['id'].present?
      dispute_fields['id'] = dispute_fields['id'].split(/[\s,]+/)
    end

    relation = where(dispute_fields)


    if params['submitted_newer'].present?
      relation =
          relation.where('case_opened_at >= :submitted_newer', submitted_newer: params['submitted_newer'])
    end

    if params['submission_type'].present?
      submission_types = YAML.load(params['submission_type'].to_s)

      relation =
          relation.where({submission_type: submission_types})
    end

    if params['submitted_older'].present?
      if params['submitted_older'].kind_of?(Date)
        relation =
          relation.where('case_opened_at < :submitted_older', submitted_older: (params['submitted_older'])+1)
      elsif params['submitted_older'].kind_of?(String)
        relation =
          relation.where('case_opened_at < :submitted_older', submitted_older: Date.parse(params['submitted_older'])+1)
      end
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
      if params['modified_older'].kind_of?(Date)
        relation =
          relation.where('updated_at < :modified_older', modified_older: params['modified_older']+1)
      elsif params['modified_older'].kind_of?(String)
        relation =
          relation.where('updated_at < :modified_older', modified_older: Date.parse(params['modified_older'])+1)
      end
    end

    if params['platform_ids'].present?
      ids = params['platform_ids'].split(',').map {|m| m.to_i}
      relation = relation.joins(:dispute_entries).where("disputes.platform_id in (:ids) or dispute_entries.platform_id in (:ids)", ids: ids)
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
    if params.present? && search_name.present? && reload == false
      save_named_search(search_name, params, user: user, project_type: 'Dispute')
    end

    relation
  end

  # Searched based on saved search.
  # @param [String] search_name the name of the saved search.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.named_search(search_name, user:, reload: false)
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
    advanced_search(search_params, search_name: nil, user: user, reload: reload)
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
      when 'unassigned'
        'Unassigned Tickets'
      when 'open'
        'Open Tickets'
      when 'open_email'
        'Open Email Tickets'
      when 'open_web'
        'Open Web Tickets'
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
        where.not(status: STATUS_RESOLVED).where(user_id: user.id)
      when 'my_disputes'
        where(user_id: user.id)
      when 'team_disputes'
        where(user_id: user.my_team)
      when 'unassigned'
        where(status: [STATUS_NEW, STATUS_REOPENED], user_id: User.where(display_name: 'Vrt Incoming').first.id)
      when 'open'
        where(status: [STATUS_NEW, STATUS_REOPENED, STATUS_CUSTOMER_PENDING, STATUS_CUSTOMER_UPDATE, STATUS_ON_HOLD, STATUS_RESEARCHING, STATUS_ESCALATED, STATUS_ASSIGNED])
      when 'open_email'
        sbrs_disputes.where(status: [STATUS_NEW, STATUS_REOPENED, STATUS_CUSTOMER_PENDING, STATUS_CUSTOMER_UPDATE, STATUS_ON_HOLD, STATUS_RESEARCHING, STATUS_ESCALATED, STATUS_ASSIGNED])
      when 'open_web'
        wbrs_disputes.where(status: [STATUS_NEW, STATUS_REOPENED, STATUS_CUSTOMER_PENDING, STATUS_CUSTOMER_UPDATE, STATUS_ON_HOLD, STATUS_RESEARCHING, STATUS_ESCALATED, STATUS_ASSIGNED])
      when 'closed'
        where(status: [CLOSED, STATUS_RESOLVED])
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
    dispute_fields = %w{disputes.id case_number case_guid org_domain subject description
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

  def self.process_status_changes(disputes, status, resolution = nil, comment = nil, current_user = nil)
    resolved_at = Time.now
    disputes.each do |dispute|
      dispute.status = status
      if resolution.present?
        dispute.resolution = resolution
        dispute.resolution_comment = comment
        dispute.case_closed_at = resolved_at
        dispute.case_resolved_at = resolved_at
        dispute.status_comment = nil
      else
        dispute.resolution = nil
        dispute.resolution_comment = nil
        dispute.status_comment = comment
      end

      unless [STATUS_NEW, STATUS_ASSIGNED].include?(dispute.status)
        dispute.user_id = current_user.id unless dispute.is_assigned?
      end

      dispute.save!
      dispute.dispute_entries.each do |entry|
        if resolution.present? && entry.resolution.blank?
          entry.resolution = resolution
          entry.resolution_comment = comment
          entry.case_closed_at = resolved_at
          entry.case_resolved_at = resolved_at
        end
        entry.status = status
        entry.save
      end

      if comment.present?
        DisputeComment.create(:user_id => current_user.id, :comment => comment, :dispute_id => dispute.id)
      end

      dispute.reload

      message = Bridge::DisputeEntryUpdateStatusEvent.new
      message.post_entries(dispute.dispute_entries)

    end
  end

  def self.create_note(current_user = nil, comment, dispute_entry_id)
    dispute_entry = DisputeEntry.find(dispute_entry_id)
    dispute_id = dispute_entry.dispute_id

    formatted_comment = dispute_entry.hostlookup + ' : ' + dispute_entry.status + ' : ' + Time.now.strftime("%m/%d/%Y %H:%M").to_s + ' : '+ comment
    DisputeComment.create(:user_id => current_user.id, :comment => formatted_comment, :dispute_id => dispute_id)
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
  def self.robust_search(search_type, search_name: nil, params: nil, user:, reload: false)
    case search_type
      when 'advanced'
        advanced_search(params, search_name: search_name, user: user, reload: reload)
      when 'named'
        named_search(search_name, user: user, reload: reload)
      when 'standard'
        standard_search(search_name, user: user).includes(:customer => [:company])
      when 'contains'
        contains_search(params['value'])
      else
        where({})
    end
  end

  def customer_name
    customer.nil? ? "" : customer.name
  end

  def customer_email
    customer.nil? ? "" : customer.email
  end

  def customer_org
    if customer.nil?
      ""
    else
      customer.company.nil? ? "" : customer.company.name
    end
  end

  # @param [Array<Dispute>] disputes collection of dispute objects
  # @return [Array<Array>] data output for data tables.

  def self.to_data_packet(disputes, user:)
    disputes.map do |dispute|

      dispute_packet = dispute.attributes.slice(*%w{id priority status resolution})
      dispute_packet[:case_number] = dispute.case_id_str
      dispute_packet[:status] = "<span class='dispute_status' id='status_#{dispute.id}'> #{dispute.status}</span>"
      if dispute.status_comment.present?
        dispute_packet[:status_comment] = dispute.status_comment
      elsif dispute.resolution_comment.present?
        dispute_packet[:status_comment] = dispute.resolution_comment
      else
        dispute_packet[:status_comment] = nil
      end
      dispute_packet[:case_link] = "<a href='/escalations/webrep/disputes/#{dispute.id}'>" + dispute_packet[:case_number] + "</a>"
      dispute_packet[:submitter_org] = dispute.customer_org
      dispute_packet[:submitter_type] = dispute.submitter_type
      dispute_packet[:submitter_domain] = dispute.org_domain
      dispute_packet[:submitter_name] = dispute.customer_name
      dispute_packet[:submitter_email] = dispute.customer_email
      dispute_packet[:dispute_summary] = dispute.problem_summary
      dispute_packet[:dispute_domain] = dispute.org_domain
      dispute_packet[:updated_at] = dispute.updated_at&.strftime("%F %T")
      unless dispute.dispute_entries.blank?
        unless dispute.dispute_entries.first[:hostname].nil?
          dispute_packet[:dispute_domain] = dispute.dispute_entries.first[:hostname]
        end
      end
      dispute_packet[:dispute_count] = dispute.entry_count&.to_s

      if dispute.resolution.nil?
        dispute_packet[:dispute_resolution] = ''
      else
        if dispute.resolution_comment.blank?
          dispute_packet[:dispute_resolution] = dispute.resolution
        else
          dispute_packet[:dispute_resolution] = "<span class='esc-tooltipped' title='#{dispute.resolution_comment}'>" + dispute.resolution + "</span>"
        end
      end

      dispute_packet[:dispute_entry_content] = entry_content_for(dispute)
      dispute_packet[:dispute_entries] = dispute.dispute_entries.map{ |de| {entry: de, rendered_platform: de.determine_platform, wbrs_rule_hits: de.dispute_rule_hits.select {|hit| hit.rule_type == "WBRS"}.pluck(:name), sbrs_rule_hits: de.dispute_rule_hits.select {|hit| hit.rule_type == "SBRS"}.pluck(:name)}}
      dispute_packet[:submission_type] = dispute.submission_type
      dispute_packet[:d_entry_preview] = dispute_packet[:dispute_entry_content].first.to_s + "<span class='dispute-count'>" + dispute_packet[:dispute_count] + "</span>"
      case
        when dispute.assignee == 'Unassigned'
          dispute_packet[:assigned_to] =
              "<span class='dispute_username' id='owner_#{dispute.id}'>Unassigned</span><button class='esc-tooltipped take-ticket-button take-dispute-#{dispute.id}' title='Assign this ticket to me' onclick='take_dispute(#{dispute.id});'></button>"

        when dispute.user_id?
          if dispute.user_id == user.id
            dispute_packet[:assigned_to] =
                "<span class='dispute_username' id='owner_#{dispute.id}'> #{dispute.user&.cvs_username} </span><button class='esc-tooltipped return-ticket-button return-ticket-#{dispute.id}' title='Return ticket.' onclick='return_dispute(#{dispute.id});'></button>"
          else
            dispute_packet[:assigned_to] =
                "<span class='dispute_username' id='owner_#{dispute.id}'> #{dispute.user&.cvs_username} </span><button class='esc-tooltipped take-ticket-button take-dispute-#{dispute.id}' title='Assign this ticket to me' onclick='take_dispute(#{dispute.id});'></button>"
          end
      end

      dispute_packet[:actions] = "<a href='/escalations/webrep/disputes/#{dispute.id}'>edit</a>"

      dispute_packet[:case_opened_at] = dispute.case_opened_at&.strftime('%Y-%m-%d %H:%M:%S')
      dispute_packet[:case_age] = dispute.dispute_age
      dispute_packet[:age_int] = (Time.now - dispute.created_at).to_i
      # dispute_packet[:suggested_disposition] = 'Malicious: Phishing'
      dispute_packet[:suggested_disposition] = dispute.suggested_d
      dispute_packet[:source] = dispute.ticket_source.nil? ? "Bugzilla" : dispute.ticket_source
      dispute_packet[:source_type] = dispute.ticket_source_type

      dispute_packet[:wbrs_score] = ''
      dispute_packet[:wbrs_rule_hits] = []

      dispute.dispute_entries.each do |d_entry|
        if dispute_packet[:wbrs_score].empty? and d_entry[:score_type] == "WBRS"
          dispute_packet[:wbrs_score] = d_entry[:score].to_s unless d_entry[:score].nil?
        end
        d_entry.dispute_rule_hits.each do |d_rule|
          dispute_packet[:wbrs_rule_hits] << d_rule.name
        end
      end
      dispute_packet[:wbrs_rule_hits] = dispute_packet[:wbrs_rule_hits].join(", ")

      dispute_packet[:platform] = dispute.determine_platform
      dispute_packet.each do |k, v|
        dispute_packet[k] = '' if dispute_packet[k].nil?
      end

      dispute_packet
    end
  end

  # collect entry content array for a specific disputes
  # entry content is using to display data in UI and for disputes export
  def self.entry_content_for(dispute)
    entry_content = []
    unless dispute.dispute_entries.blank?
      dispute.dispute_entries.each do |entry|
        unless entry[:ip_address].nil?
          entry_content.push(entry[:ip_address])
        end
        unless entry[:uri].nil?
          entry_content.push(entry[:uri])
        end
      end
    end
    entry_content
  end

  def peek(user:)
    if dispute_peeks.where(user: user).exists?
      dispute_peeks.where(user: user).update_all(updated_at: Time.now)
    else
      dispute_peeks.create(user: user)
      DisputePeek.delete_excess(user: user)
    end
  end

  # Assigns a user to given disputes
  # @param [User|Integer] user the user to assign this dispute to
  # @param [Array<Integer>|Integer] dispute_ids the disputes to assign
  # @return [Array<Dispute>] the disputes updated
  def self.assign(user, dispute_ids)
    user_id = user.kind_of?(User) ? user.id : user
    accepted_at = Time.now

    disputes = Dispute.where(id: dispute_ids).where.not(status: [
      Dispute::TI_NEW, Dispute::STATUS_RESOLVED, Dispute::STATUS_RESOLVED_FIXED_FP, Dispute::STATUS_RESOLVED_FIXED_FN,
      Dispute::STATUS_RESOLVED_UNCHANGED
    ])

    disputes_ary = disputes.includes(:dispute_entries)
    entries = DisputeEntry.where(dispute: disputes_ary, status: [DisputeEntry::NEW, DisputeEntry::STATUS_REOPENED, DisputeEntry::ASSIGNED])
    entries_ary = entries.all.to_a

    Dispute.transaction do
      disputes.update_all(user_id: user_id, status: Dispute::STATUS_ASSIGNED, case_accepted_at: accepted_at)
      if entries_ary.any?
        entries_ary.each do |entry|
          if entry.status != DisputeEntry::STATUS_RESOLVED
            entry.status = DisputeEntry::ASSIGNED
            entry.case_accepted_at = accepted_at
            entry.save
          end
        end

      end
    end
    # send entries for separately to avoid bug in DisputeEntryUpdateStatusEvent#post entries
    # when we send ticket_source_key and status for first element in disputes_ary array
    disputes_ary.each do |dispute|
      entries = dispute.dispute_entries.where(status: [DisputeEntry::NEW, DisputeEntry::STATUS_REOPENED, DisputeEntry::ASSIGNED])

      Bridge::DisputeEntryUpdateStatusEvent.new.post_entries(entries.to_a)
    end 

    disputes_ary
  end

  def self.take_tickets(dispute_ids, user:)
    Dispute.transaction do
      unless 0 == Dispute.where(id: dispute_ids).where.not(user_id: User.vrtincoming.id).count
        raise 'Some of these ticket are already assigned.'
      end
      Dispute.assign(user, dispute_ids)
    end
  end

  def return_dispute
    update(user_id: User.vrtincoming.id)

    if status == STATUS_ASSIGNED
      update(status: 'NEW', case_accepted_at: nil)

      dispute_entries.each do |dispute_entry|
        if dispute_entry.status == DisputeEntry::ASSIGNED
          dispute_entry.update(status: 'NEW', case_accepted_at: nil)
        end
      end
    end

  end


  #####FOR REPORTING#######

  def self.open_tickets_report(users, from, to)
    #from = "Mon, 4 Jul 2018 17:40:08 GMT"

    status_array = [STATUS_ASSIGNED, STATUS_REOPENED, STATUS_CUSTOMER_PENDING, STATUS_CUSTOMER_UPDATE, STATUS_RESEARCHING, STATUS_ESCALATED, STATUS_ON_HOLD]

    from = Time.parse(from)
    to = Time.parse(to)

    report_data = {}
    report_data[:table_data] = []
    user_ids = users.pluck(:id)
    results = Dispute.includes(:dispute_entries).where("created_at between '#{from}' and '#{to}'").where(:user_id => user_ids).where(:status => status_array).where.not(:submission_type => nil, :submitter_type => nil)

    report_data[:ticket_count] = results.size
    report_data[:entries_count] = results.map {|result| result.dispute_entries}.flatten.select {|entry| entry.status != DisputeEntry::STATUS_RESOLVED }.size

    report_data[:customer_count] = results.map {|result| result.dispute_entries}.flatten.select {|entry| entry.dispute.submitter_type == SUBMITTER_TYPE_CUSTOMER }.size  #results.select {|result| result.submitter_type == SUBMITTER_TYPE_CUSTOMER}.size
    report_data[:guest_count] = results.map {|result| result.dispute_entries}.flatten.select {|entry| entry.dispute.submitter_type == SUBMITTER_TYPE_NONCUSTOMER }.size #results.select {|result| result.submitter_type == SUBMITTER_TYPE_NONCUSTOMER}.size
    report_data[:email_count] = results.map {|result| result.dispute_entries}.flatten.select {|entry| entry.dispute.submission_type.downcase == 'e' }.size #results.select {|result| result.submission_type.downcase == 'e'}.size
    report_data[:web_count] = results.map {|result| result.dispute_entries}.flatten.select {|entry| entry.dispute.submission_type.downcase == 'w' }.size#results.select {|result| result.submission_type.downcase == 'w'}.size
    report_data[:email_web_count] = results.map {|result| result.dispute_entries}.flatten.select {|entry| entry.dispute.submission_type.downcase == 'ew' }.size#results.select {|result| result.submission_type.downcase == 'ew'}.size

    results.each do |result|
      entry_count = result.dispute_entries.size
      entry_preview = []
      result.dispute_entries.each do |entry|
        if entry.ip_address
          entry_preview.push(entry.ip_address)
        end
        if entry.uri
          entry_preview.push(entry.uri)
        end
      end
      entry_preview.to_s.inspect

      unless result.dispute_comments.empty?
        last_comment_time = result.dispute_comments.last.created_at.to_s
        last_comment_preview = "<span class='esc-tooltipped' title='#{result.dispute_comments.last.comment.truncate(140)}'>#{last_comment_time}</span>"
      else
        last_comment_preview = "<span class='missing-data'>No comments</span>"
      end

      ticket_user = result.user.cvs_username
      if !result.dispute_emails.present?
        dispute_emails_count = 0
      else
        dispute_emails_count = result.dispute_emails&.count
      end
      report_data[:table_data] << {:case_number => result.id,
                      :case_link => "<a href='/escalations/webrep/disputes/#{result.id}'>#{result.case_id_str}</a>",
                      :status => result.status,
                      :d_entry_preview => "<span class='dispute_entry_content_first'>#{result.dispute_entries.first&.hostlookup}</span><span class='dispute-count esc-tooltipped' title='#{entry_preview.join(",")}'>#{entry_count}</span>",
                      :age => distance_of_time_in_words(Time.now, result.created_at),
                      :submitter_type => result.submitter_type.downcase,
                      :submission_type => result.submission_type.upcase,
                      :last_comment => last_comment_preview,
                      :owner => ticket_user,
                      :priority => result.priority,
                      :last_email_date => result.dispute_emails&.last&.updated_at&.strftime("%FT%T"),
                      :total_email_count => dispute_emails_count
      }
    end
    report_data
  end

  def self.closed_tickets_report(users, from, to)

    #from = "Mon, 4 Jul 2018 17:40:08 GMT"

    status_array = [STATUS_RESOLVED]

    from = Time.parse(from)
    to = Time.parse(to)

    report_data = {}
    report_data[:table_data] = []
    user_ids = users.pluck(:id)
    results = Dispute.includes(:dispute_entries).where("created_at between '#{from}' and '#{to}'").where(:user_id => user_ids).where(:status => status_array).where.not(:submission_type => nil, :submitter_type => nil)

    report_data[:ticket_count] = results.size
    report_data[:entries_count] = results.map {|result| result.dispute_entries}.flatten.select {|entry| entry.status == DisputeEntry::STATUS_RESOLVED }.size

    report_data[:customer_count] = results.map {|result| result.dispute_entries}.flatten.select {|entry| entry.dispute.submitter_type == SUBMITTER_TYPE_CUSTOMER }.size  #results.select {|result| result.submitter_type == SUBMITTER_TYPE_CUSTOMER}.size
    report_data[:guest_count] = results.map {|result| result.dispute_entries}.flatten.select {|entry| entry.dispute.submitter_type == SUBMITTER_TYPE_NONCUSTOMER }.size #results.select {|result| result.submitter_type == SUBMITTER_TYPE_NONCUSTOMER}.size
    report_data[:email_count] = results.map {|result| result.dispute_entries}.flatten.select {|entry| entry.dispute.submission_type.downcase == 'e' }.size #results.select {|result| result.submission_type.downcase == 'e'}.size
    report_data[:web_count] = results.map {|result| result.dispute_entries}.flatten.select {|entry| entry.dispute.submission_type.downcase == 'w' }.size#results.select {|result| result.submission_type.downcase == 'w'}.size
    report_data[:email_web_count] = results.map {|result| result.dispute_entries}.flatten.select {|entry| entry.dispute.submission_type.downcase == 'ew' }.size#results.select {|result| result.submission_type.downcase == 'ew'}.size



    results.each do |result|
      if !result.case_resolved_at
        result.case_resolved_at = Time.now
      end
      entry_count = result.dispute_entries.size
      entry_preview = []
      result.dispute_entries.each do |entry|
        if entry.ip_address
          entry_preview.push(entry.ip_address)
        end
        if entry.uri
          entry_preview.push(entry.uri)
        end
      end
      entry_preview.to_s.inspect
      ticket_user = result.user.cvs_username

      if !result.dispute_emails.present?
        dispute_emails_count = 0
      else
        dispute_emails_count = result.dispute_emails&.count
      end

      report_data[:table_data] << {:case_number => result.id,
                      :case_link => "<a href='/escalations/webrep/disputes/#{result.id}'>#{result.case_id_str}</a>",
                      # :dispute => result.dispute_entries.first.hostlookup,
                      :d_entry_preview => "<span class='dispute_entry_content_first'>#{result.dispute_entries.first&.hostlookup}</span><span class='dispute-count esc-tooltipped' title='#{entry_preview}'>#{entry_count}</span>",

                      :time_to_close => distance_of_time_in_words(result.created_at, result.case_resolved_at),

                      :submitter_type => result.submitter_type.downcase,
                      :submission_type => result.submission_type.upcase,
                      :priority => result.priority,
                      :owner => ticket_user,
                      :last_email_date => result.dispute_emails&.last&.updated_at&.strftime("%FT%T"),
                      :total_email_count => dispute_emails_count
      }
    end

    report_data
  end

  def self.ticket_entries_closed_by_day_report(users, from, to)
    #users = [User.find(1)]
    #from = "Wed, 5 Sep 2018 17:40:08 GMT"
    #to = "Thu, 20 Sep 2018 17:40:08 GMT"

    from = Time.parse(from)
    to = Time.parse(to)

    swap_day = from
    report_data = {}

    user_ids = users.pluck(:id)
    main_results = Dispute.joins(:dispute_entries).eager_load(:dispute_entries).where(:user_id => user_ids).where("disputes.created_at between '#{from}' and '#{to}'").where("dispute_entries.status in ('#{DisputeEntry::RESOLVED}', '#{DisputeEntry::STATUS_RESOLVED}')")

    all_entries = main_results.map {|result| result.dispute_entries}.flatten.uniq

    report_data[:report_labels] = []
    report_data[:report_total_data] = []
    report_data[:report_w_data] = []
    report_data[:report_e_data] = []
    report_data[:report_ew_data] = []

    while Date.parse(swap_day.to_s) != (Date.parse(to.to_s) + 1.day)

      day_all_totals = 0
      day_e_totals = 0
      day_w_totals = 0
      day_ew_totals = 0
      report_data[:report_labels] << swap_day.strftime("%a %b %d, %Y")

      report_day_count = 0
      day_results = all_entries.select {|result| Date.parse(result.created_at.to_s) == Date.parse(swap_day.to_s)}

      if day_results.present?

        day_results.each do |day_result|
          if day_result.status == DisputeEntry::STATUS_RESOLVED
            day_all_totals += 1

            case day_result.dispute.submission_type&.downcase
              when 'e'
                day_e_totals += 1
              when 'w'
                day_w_totals += 1
              when 'ew'
                day_ew_totals += 1
            end
          end
        end
      end

      report_data[:report_total_data] << day_all_totals
      report_data[:report_w_data] << day_w_totals
      report_data[:report_e_data] << day_e_totals
      report_data[:report_ew_data] << day_ew_totals

      swap_day = swap_day + 1.day
    end

    report_data

  end

  def self.ticket_time_to_close_report(user_id, from, to)

    status_array = [STATUS_RESOLVED]

    from = Time.parse(from)
    to = Time.parse(to)

    report_data = {}
    report_data[:ticket_numbers] = []
    report_data[:close_times] = []

    main_results = Dispute.where(:user_id => user_id).where("disputes.created_at between '#{from}' and '#{to}'").where(:status => status_array).where.not(:submission_type => nil, :submitter_type => nil)

    main_results.each do |result|
      if !result.case_resolved_at
        result.case_resolved_at = Time.now
      end
      report_data[:ticket_numbers] << result.id
      report_data[:close_times] << ((result.case_resolved_at - result.created_at) / 3600 )
    end

    report_data

  end

  def self.closed_ticket_entries_by_resolution_report(users, from, to, submission_types = nil)
    #users = [User.find(217), User.find(197)]
    #from = "Thu, 16 Aug 2018 17:40:08 GMT"
    #to = "Thu, 20 Sep 2018 17:40:08 GMT"
    #submission_types = ['e', 'w']

    from = Time.parse(from)
    to = Time.parse(to)

    user_ids = users.pluck(:id)

    if submission_types.present?
      main_results = Dispute.joins(:dispute_entries).eager_load(:dispute_entries).where(:user_id => user_ids).where("disputes.created_at between '#{from}' and '#{to}'").where(:submission_type => submission_types).where("dispute_entries.status = '#{STATUS_RESOLVED}'")
    else
      main_results = Dispute.joins(:dispute_entries).eager_load(:dispute_entries).where(:user_id => user_ids).where("disputes.created_at between '#{from}' and '#{to}'").where("dispute_entries.status = '#{STATUS_RESOLVED}'")
    end

    all_entries = main_results.map {|result| result.dispute_entries}.flatten.select {|entry| entry.case_resolved_at.present?}.uniq
    total_count = all_entries.size

    results = {}
    results[:chart_data] = []
    results[:chart_labels] = ["Fixed FN", "Unchanged", "Fixed FP", "Other"]
    results[:table_data] = []

    results[:chart_data] << all_entries.select {|entry| entry.resolution == DisputeEntry::STATUS_RESOLVED_FIXED_FN}.size.to_f / total_count.to_f
    results[:chart_data] << all_entries.select {|entry| entry.resolution == DisputeEntry::STATUS_RESOLVED_UNCHANGED}.size.to_f / total_count.to_f
    results[:chart_data] << all_entries.select {|entry| entry.resolution == DisputeEntry::STATUS_RESOLVED_FIXED_FP}.size.to_f / total_count.to_f
    results[:chart_data] << all_entries.select {|entry| entry.resolution == DisputeEntry::STATUS_RESOLVED_OTHER}.size.to_f / total_count.to_f

    if results[:chart_data][0].nan?
      results[:chart_data][0] = 0
    end

    if results[:chart_data][1].nan?
      results[:chart_data][1] = 0
    end

    if results[:chart_data][2].nan?
      results[:chart_data][2] = 0
    end

    if results[:chart_data][3].nan?
      results[:chart_data][3] = 0
    end

    results[:table_data] << {:resolution => LABEL_RESOLVED_FIXED_FP,
                             :percent => (results[:chart_data][2] * 100).round(2),
                             :count => all_entries.select {|entry| entry.resolution == DisputeEntry::STATUS_RESOLVED_FIXED_FP}.size
                             }

    results[:table_data] << {:resolution => LABEL_RESOLVED_FIXED_FN,
                             :percent => (results[:chart_data][0] * 100).round(2),
                             :count => all_entries.select {|entry| entry.resolution == DisputeEntry::STATUS_RESOLVED_FIXED_FN}.size
    }

    results[:table_data] << {:resolution => LABEL_RESOLVED_UNCHANGED,
                             :percent => (results[:chart_data][1] * 100).round(2),
                             :count => all_entries.select {|entry| entry.resolution == DisputeEntry::STATUS_RESOLVED_UNCHANGED}.size
    }

    results[:table_data] << {:resolution => LABEL_RESOLVED_OTHER,
                             :percent => (results[:chart_data][3] * 100).round(2),
                             :count => all_entries.select {|entry| entry.resolution == DisputeEntry::STATUS_RESOLVED_OTHER}.size
    }

    results

  end

  def self.auto_ticket_entries_by_resolution_report(from, to, submission_types = nil)

    from = Time.parse(from)
    to = Time.parse(to)

    vrt =  User.where(cvs_username: 'vrtincom').first
    vrt_id = vrt.id

    if submission_types.present?
      closed_entries = Dispute.joins(:dispute_entries).eager_load(:dispute_entries).where(:user_id => vrt_id).where("disputes.created_at between '#{from}' and '#{to}'").where(:submission_type => submission_types).where("dispute_entries.status = '#{STATUS_RESOLVED}'")
    else
      closed_entries = Dispute.joins(:dispute_entries).eager_load(:dispute_entries).where(:user_id => vrt_id).where("disputes.created_at between '#{from}' and '#{to}'").where("dispute_entries.status = '#{STATUS_RESOLVED}'")
    end

    all_entries = closed_entries.map {|result| result.dispute_entries}.flatten.select {|entry| entry.case_resolved_at.present?}.uniq

    entries_duplicates = all_entries.select {|entry| entry.resolution == "DUPLICATE"}
    entries_fixed_fn = all_entries.select {|entry| entry.resolution == DisputeEntry::STATUS_RESOLVED_FIXED_FN}
    entries_unchanged = all_entries.select {|entry| entry.resolution == DisputeEntry::STATUS_RESOLVED_UNCHANGED}

    total_count = all_entries.size

    results = {}
    results[:chart_data] = []
    results[:chart_labels] = ["Fixed FN", "Duplicates", "Unchanged" ]
    results[:chart_data] << entries_fixed_fn.size.to_f / total_count.to_f
    results[:chart_data] << entries_duplicates.size.to_f / total_count.to_f
    results[:chart_data] << entries_unchanged.size.to_f / total_count.to_f

    if results[:chart_data][0].nan?
      results[:chart_data][0] = 0
    end

    if results[:chart_data][1].nan?
      results[:chart_data][1] = 0
    end

    if results[:chart_data][2].nan?
      results[:chart_data][2] = 0
    end

    results[:table_data] = []

    results[:table_data] << {:resolution => LABEL_RESOLVED_FIXED_FN,
                             :percent => (results[:chart_data][0] * 100).round(2),
                             :count => entries_fixed_fn.size
    }

    results[:table_data] << {:resolution => "Duplicates",
                             :percent => (results[:chart_data][1] * 100).round(2),
                             :count => entries_duplicates.size
    }
    results[:table_data] << {:resolution => LABEL_RESOLVED_UNCHANGED,
                             :percent => (results[:chart_data][2] * 100).round(2),
                             :count => entries_unchanged.size
    }
    results[:table_data] << {:resolution => "Total",
                             :percent => 100,
                             :count => total_count.to_f
    }
    results

  end

  def self.all_closed_tickets_manual_vs_auto_report(from, to, submission_types = nil)

    from = Time.parse(from)
    to = Time.parse(to)

    vrt =  User.where(cvs_username: 'vrtincom').first
    vrt_id = vrt.id

    if submission_types.present?
      manual_results = Dispute.where.not(:user_id => vrt_id).where("disputes.created_at between '#{from}' and '#{to}'").where(:submission_type => submission_types).where("status = '#{STATUS_RESOLVED}'")
      auto_results = Dispute.where(:user_id => vrt_id).where("disputes.created_at between '#{from}' and '#{to}'").where(:submission_type => submission_types).where("status = '#{STATUS_RESOLVED}'")

    else
      manual_results = Dispute.where.not(:user_id => vrt_id).where("disputes.created_at between '#{from}' and '#{to}'").where("status = '#{STATUS_RESOLVED}'")
      auto_results = Dispute.where(:user_id => vrt_id).where("disputes.created_at between '#{from}' and '#{to}'").where("status = '#{STATUS_RESOLVED}'")
    end

    total_count = manual_results.size + auto_results.size

    results = {}

    results[:chart_data] = []
    results[:chart_labels] = [ "Manually Resolved Tickets", "Automatically Resolved Tickets"]

    results[:chart_data] << manual_results.size.to_f / total_count.to_f
    results[:chart_data] << auto_results.size.to_f / total_count.to_f

    if results[:chart_data][0].nan?
      results[:chart_data][0] = 0
    end

    if results[:chart_data][1].nan?
      results[:chart_data][1] = 0
    end

    results[:table_data] = []

    results[:table_data] << {:resolution => "Automatically Resolved Tickets",
                             :percent => (results[:chart_data][1] * 100).round(2),
                             :count => auto_results.size
    }

    results[:table_data] << {:resolution => "Manually Closed Tickets",
                             :percent => (results[:chart_data][0] * 100).round(2),
                             :count => manual_results.size.to_f
    }

    results[:table_data] << {:resolution => "Total Closed Tickets",
                             :percent => 100,
                             :count => total_count.to_f
    }

    results

  end

  def self.all_tickets_manual_vs_auto_close_report(from, to, submission_types = nil)

    from = Time.parse(from)
    to = Time.parse(to)

    vrt =  User.where(cvs_username: 'vrtincom').first
    vrt_id = vrt.id

    if submission_types.present?
      all_results = Dispute.where("disputes.created_at between '#{from}' and '#{to}'").where(:submission_type => submission_types)
      auto_results = Dispute.where(:user_id => vrt_id).where("disputes.created_at between '#{from}' and '#{to}'").where(:submission_type => submission_types).where("status = '#{STATUS_RESOLVED}'")

    else
      all_results = Dispute.where("disputes.created_at between '#{from}' and '#{to}'")
      auto_results = Dispute.where(:user_id => vrt_id).where("disputes.created_at between '#{from}' and '#{to}'").where("status = '#{STATUS_RESOLVED}'")
    end

    total_count = all_results.size

    results = {}

    results[:chart_data] = []
    results[:chart_labels] = [ "All Tickets", "Automatically Resolved Tickets"]

    results[:chart_data] << (all_results.size.to_f - auto_results.size.to_f)/ total_count.to_f
    results[:chart_data] << auto_results.size.to_f / total_count.to_f

    if results[:chart_data][0].nan?
      results[:chart_data][0] = 0
    end

    if results[:chart_data][1].nan?
      results[:chart_data][1] = 0
    end

    results[:table_data] = []

    results[:table_data] << {:resolution => "Automatically Resolved Tickets",
                             :percent => (results[:chart_data][1] * 100).round(2),
                             :count => auto_results.size
    }

    results[:table_data] << {:resolution => "Non-auto resolved tickets",
                             :percent => (results[:chart_data][0] * 100).round(2),
                             :count => (all_results.size - auto_results.size)
    }

    results[:table_data] << {:resolution => "Total Submitted Tickets",
                             :percent => 100,
                             :count => all_results.size.to_f
    }

    results

  end

  def self.tickets_submitted_by_submitter_per_day(from, to)

    #from = "Mon, 6 Aug 2018 17:40:08 GMT"
    #to = "Fri, 10 Aug 2018 17:40:08 GMT"

    from = Time.parse(from)
    to = Time.parse(to)

    #main_results = Dispute.joins(:dispute_entries).where("disputes.created_at between '#{from}' and '#{to}'")
    main_results = Dispute.where("disputes.created_at between '#{from}' and '#{to}'")
    report_data = {}
    final_report_data = {}

    final_report_data[:chart_labels] = []
    final_report_data[:customer_chart_data] = []
    final_report_data[:guest_chart_data] = []


    swap_day = from

    while Date.parse(swap_day.to_s) != (Date.parse(to.to_s) + 1.day)

       report_data[swap_day.to_s] = {}
       report_data[swap_day.to_s][:customer_count] = 0
       report_data[swap_day.to_s][:guest_count] = 0

       final_report_data[:chart_labels] << swap_day.strftime("%a %b %d, %Y")

       day_results = main_results.select {|result| Date.parse(result.created_at.to_s) == Date.parse(swap_day.to_s)}.uniq

       day_results.each do |result|
         if result.submitter_type == SUBMITTER_TYPE_CUSTOMER
           report_data[swap_day.to_s][:customer_count] += 1
         end
         if result.submitter_type == SUBMITTER_TYPE_NONCUSTOMER
           report_data[swap_day.to_s][:guest_count] += 1
         end
       end

       final_report_data[:customer_chart_data] << report_data[swap_day.to_s][:customer_count]
       final_report_data[:guest_chart_data] << report_data[swap_day.to_s][:guest_count]

       swap_day = swap_day + 1.day
    end

    final_report_data

  end

  def self.ticket_entries_closed_by_ticket_owner(users, from, to)

    from = Time.parse(from)
    to = Time.parse(to)

    user_ids = users.pluck(:id)

    main_results = Dispute.joins(:dispute_entries).eager_load(:dispute_entries).where("disputes.created_at between '#{from}' and '#{to}'").where(:user_id => user_ids).where.not(:submission_type => nil, :submitter_type => nil).where("dispute_entries.status = '#{STATUS_RESOLVED}'")
    all_entries = main_results.map {|result| result.dispute_entries}.flatten.uniq

    report_data = {}
    final_data = {}
    final_data[:report_labels] = []
    final_data[:report_data] = []

    users.each do |user|
      report_data[user.cvs_username] = 0
    end

    all_entries.each do |entry|
      if entry.status == DisputeEntry::STATUS_RESOLVED && entry.dispute.user.present?
        report_data[entry.dispute.user.cvs_username] += 1
      end
    end

    report_data.keys.each do |key|
      final_data[:report_labels] << key
      final_data[:report_data] << report_data[key]
    end

    final_data

  end

  def self.average_time_to_close_tickets_by_ticket_owner(users, from, to)

    from = Time.parse(from)
    to = Time.parse(to)

    raw_data = {}
    report = {}
    report_data = []

    report_labels = []


    user_ids = users.pluck(:id)

    users.each do |user|
      raw_data[user.cvs_username] = []
    end

    main_results = Dispute.where(:user_id => user_ids).where("disputes.created_at between '#{from}' and '#{to}'").where("disputes.status = '#{STATUS_RESOLVED}'").where.not(:submission_type => nil, :submitter_type => nil)

    main_results.each do |result|
      if !result.case_resolved_at
        result.case_resolved_at = Time.now
      end
      raw_data[result.user.cvs_username] << ((result.case_resolved_at - result.created_at) / 3600 )
    end

    raw_data.each do |k, v|
      avg = v.inject{ |sum, el| sum + el }.to_f / v.size

      report_labels << k
      if !avg.nan?
        #report_data[k] = avg
        report_data << avg
      else
        #report_data[k] = 0
        report_data << 0
      end
    end

    report[:report_data] = report_data
    report[:report_labels] = report_labels

    report
  end

  def self.ticket_entry_resolution_by_ticket_owner(users, from, to)

    from = Time.parse(from)
    to = Time.parse(to)

    user_ids = users.pluck(:id)

    main_results = Dispute.joins(:dispute_entries).eager_load(:dispute_entries).where(:user_id => user_ids).where("disputes.created_at between '#{from}' and '#{to}'").where.not(:submission_type => nil, :submitter_type => nil).where("dispute_entries.status = '#{STATUS_RESOLVED}'")

    all_entries = main_results.map {|result| result.dispute_entries}.flatten.select {|entry| entry.case_resolved_at.present?}.flatten.uniq


    results = {}
    results[:chart_data] = {}
    #results[:table_data] = []
    final_data = {}
    users.each do |user|
      results[:chart_data][user.cvs_username] = {}
      results[:chart_data][user.cvs_username][DisputeEntry::STATUS_RESOLVED_FIXED_FP] = 0
      results[:chart_data][user.cvs_username][DisputeEntry::STATUS_RESOLVED_FIXED_FN] = 0
      results[:chart_data][user.cvs_username][DisputeEntry::STATUS_RESOLVED_UNCHANGED] = 0
      results[:chart_data][user.cvs_username][DisputeEntry::STATUS_RESOLVED_OTHER] = 0
    end

    all_entries.each do |entry|
      case entry.resolution
        when DisputeEntry::STATUS_RESOLVED_FIXED_FP
          results[:chart_data][entry.dispute.user.cvs_username][DisputeEntry::STATUS_RESOLVED_FIXED_FP] += 1
          #results[:chart_data][:total][DisputeEntry::STATUS_RESOLVED_FIXED_FP] += 1
        when DisputeEntry::STATUS_RESOLVED_FIXED_FN
          results[:chart_data][entry.dispute.user.cvs_username][DisputeEntry::STATUS_RESOLVED_FIXED_FN] += 1
          #results[:chart_data][:total][DisputeEntry::STATUS_RESOLVED_FIXED_FN] += 1
        when DisputeEntry::STATUS_RESOLVED_UNCHANGED
          results[:chart_data][entry.dispute.user.cvs_username][DisputeEntry::STATUS_RESOLVED_UNCHANGED] += 1
          #results[:chart_data][:total][DisputeEntry::STATUS_RESOLVED_UNCHANGED] += 1
        when DisputeEntry::STATUS_RESOLVED_OTHER
          results[:chart_data][entry.dispute.user.cvs_username][DisputeEntry::STATUS_RESOLVED_OTHER] += 1
          #results[:chart_data][:total][DisputeEntry::STATUS_RESOLVED_OTHER] += 1
      end
    end

    final_data[:ticket_owners] = []
    final_data[:fixed_fp_tickets] = []
    final_data[:fixed_fn_tickets] = []
    final_data[:unchanged_tickets] = []
    final_data[:other_tickets] = []


    results[:chart_data].each do |k, v|
      final_data[:ticket_owners] << k
      final_data[:fixed_fp_tickets] << v[DisputeEntry::STATUS_RESOLVED_FIXED_FP]
      final_data[:fixed_fn_tickets] << v[DisputeEntry::STATUS_RESOLVED_FIXED_FN]
      final_data[:unchanged_tickets] << v[DisputeEntry::STATUS_RESOLVED_UNCHANGED]
      final_data[:other_tickets] << v[DisputeEntry::STATUS_RESOLVED_OTHER]
    end

    final_data

  end

  def self.rulehits_for_false_positive_resolutions(users, from , to)

    from = Time.parse(from)
    to = Time.parse(to)


    user_ids = users.pluck(:id)

    main_results = Dispute.where(:user_id => user_ids).where("disputes.created_at between '#{from}' and '#{to}'").where.not(:submission_type => nil, :submitter_type => nil).includes(dispute_entries: :dispute_rule_hits)

    all_entries = main_results.map {|result| result.dispute_entries}.flatten.select {|entry| entry.case_resolved_at.present?}.flatten.uniq

    fp_entries = all_entries.select {|entry| entry.resolution == DisputeEntry::STATUS_RESOLVED_FIXED_FP}

    rulehits_found = fp_entries.map { |entry| entry.dispute_rule_hits.pluck(:name)}.flatten.uniq

    rulehit_types = {}

    rulehits_found.each do |rh|
      rulehit_types[rh] = 0
    end

    fp_entries.each do |entry|
      entry.dispute_rule_hits.each do |rh|
        rulehit_types[rh.name] += 1
      end
    end

    rulehit_types.reject! {|k, v| %w"dotq
      alx_cln
      tuse
      a500
      deli
      csdw
      suwl
      ciwl
      vsvd
      wlh
      wlm
      wlw".include? k } # According to Jayme, hit counts for these rules can be omitted (https://jira.vrt.sourcefire.com/browse/WEB-5082)

    rulehit_types = Hash[rulehit_types.sort_by {|k,v| v}[0..24].reverse] # Limit rule hits to the top 25

    final_data = {}
    final_data[:rules] = []
    final_data[:rule_hits] = []

    rulehit_types.each do |k, v|
      final_data[:rules] << k
      final_data[:rule_hits] << v
    end

    final_data

  end

  def self.populate_top_banner()

    main_results = Dispute.includes(:dispute_entries)

    results = {}
    results[:valid_tickets_total] = 0
    results[:valid_entries_total] = 0
    results[:invalid_tickets_total] = 0

    main_results.each do |result|
      if ![DUPLICATE].include?(result.status)
        if result.status == RESOLVED
          if ![STATUS_RESOLVED_INVALID, STATUS_RESOLVED_TEST, STATUS_RESOLVED_OTHER].include?(result.resolution)
            results[:valid_tickets_total] += 1
            results[:valid_entries_total] += result.dispute_entries.size
          end

          if [STATUS_RESOLVED_INVALID, STATUS_RESOLVED_TEST, STATUS_RESOLVED_OTHER].include?(result.resolution)
            results[:invalid_tickets_total] += 1
          end
        else
          results[:valid_tickets_total] += 1
          results[:valid_entries_total] += result.dispute_entries.size
        end

      end

      if [DUPLICATE].include?(result.status)
        results[:invalid_tickets_total] += 1
      end
    end

    results

  end

  def self.sync_all
    AdminTask.execute_task(:sync_disputes_with_ti, {})
  end

  def manual_sync
    message = Bridge::DisputeEntryUpdateStatusEvent.new
    message.post_entries(self.dispute_entries)
  end

  def self.process_quick_bulk_entries(data, user)

    ips = []
    urls = []

    data.keys.each do |key|
      if DisputeEntry.is_ip?(key)
        ips << key
      else
        urls << key
      end
    end

    customer = Customer.where(name: 'Dispute Analyst').first_or_create(name: 'Dispute Analyst')
    summary = "New Web Reputation Dispute generated at #{DateTime.now.utc.strftime("%Y-%m-%d %H:%M")}"
    bugzilla_rest_session = BugzillaRest::Session.default_session


    full_description = %Q{
          IPs: #{ips}
          URIs: #{urls}
          Problem Summary: #{summary}
    }

    bug_attrs = {
        'product' => 'Escalations Console',
        'component' => 'IP/Domain',
        'summary' => summary,
        'version' => 'unspecified', #self.version,
        'description' => full_description,
        'priority' => 'Unspecified',
        'classification' => 'unclassified',
    }

    bug_proxy = bugzilla_rest_session.create_bug(bug_attrs)

    new_dispute = Dispute.new

    new_dispute.id = bug_proxy.id
    new_dispute.user_id = user.id

    new_dispute.case_opened_at = Time.now
    new_dispute.case_closed_at = Time.now
    new_dispute.case_resolved_at = Time.now
    new_dispute.description = full_description
    new_dispute.problem_summary = summary

    new_dispute.status = STATUS_RESOLVED
    new_dispute.resolution = STATUS_RESOLVED_QUICK_BULK

    new_dispute.customer_id = customer&.id

    new_dispute.save!

    ips.each do |ip|
      new_dispute_entry = new_dispute.dispute_entries.build(entry_type: 'IP', ip_address: ip)
      new_dispute_entry.case_opened_at = Time.now
      new_dispute_entry.case_closed_at = Time.now
      new_dispute_entry.case_resolved_at = Time.now
      new_dispute_entry.status = DisputeEntry::STATUS_RESOLVED
      new_dispute_entry.resolution = DisputeEntry::STATUS_RESOLVED_QUICK_BULK
      new_dispute_entry.save!
      #DisputeEntry.quick_bulk_rep_update(ip, data[ip], note)
    end

    urls.each do |url|
      new_dispute_entry = new_dispute.dispute_entries.build(entry_type: 'URI/DOMAIN', uri: url)
      new_dispute_entry.case_opened_at = Time.now
      new_dispute_entry.case_closed_at = Time.now
      new_dispute_entry.case_resolved_at = Time.now
      new_dispute_entry.status = DisputeEntry::STATUS_RESOLVED
      new_dispute_entry.resolution = DisputeEntry::STATUS_RESOLVED_QUICK_BULK
      new_dispute_entry.save!
      #DisputeEntry.quick_bulk_rep_update(url, data[url], note)
    end

    return_hash = {}
    return_hash[:dispute_id] = new_dispute.id
    return_hash[:dispute_entries] = []
    new_dispute.dispute_entries.each do |entry|
      return_hash[:dispute_entries] << {:dispute_entry_id => entry.id, :entry => entry.hostlookup}
    end  

    return return_hash
  end


  def self.convert_to_complaint(params, current_user, auto_resolve = nil)
    dispute = Dispute.find(params[:dispute_id])
    suggested_category_entries = params[:suggested_categories]

    platform_id = nil

    package = {}
    package[:entries] = []
    package[:convert_to] = "Complaint"
    package[:internal_message] = params[:summary] + " | " + "original analyst console webrep ticket: #{dispute.id.to_s}"
    package[:email] = dispute&.customer&.email
    package[:name] = dispute&.customer&.name
    package[:company_name] = dispute&.customer&.company&.name

    suggested_category_entries.each do |sugg|
      if dispute.platform_id.present?
        platform_id = dispute.platform_id
      else
        disp_entry = dispute.dispute_entries.select {|c| c.hostlookup == sugg[1]['entry']}.first
        if disp_entry.present?
          platform_id = disp_entry.platform_id unless disp_entry.platform_id.blank?
        end
      end
      entry = {}
      entry[:entry] = sugg[1]['entry']
      entry[:suggested_categories] = sugg[1]['suggested_categories'].split(",")
      entry[:platform_id] = platform_id
      package[:entries] << entry
    end

    conn = ::Bridge::TicketConversionEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: dispute.ticket_source_key, ac_id: dispute.id)
    conn.post(package)

    new_comment = DisputeComment.new
    new_comment.dispute_id = dispute.id
    new_comment.user_id = current_user.id
    new_comment.comment = "Converted from TE ticket to SDO ticket"
    new_comment.save

    #set status and resolution here with a message
    #send update to bridge

    dispute.status = STATUS_RESOLVED
    dispute.resolution = STATUS_RESOLVED_INVALID
    if auto_resolve.present?
      if dispute.submitter_type == SUBMITTER_TYPE_CUSTOMER
        dispute.resolution_comment = AUTO_TICKET_CONVERSION_CUSTOMER_MESSAGE
      else
        dispute.resolution_comment = AUTO_NC_TICKET_CONVERSION_CUSTOMER_MESSAGE
      end
      dispute.resolution_comment = AUTO_TICKET_CONVERSION_CUSTOMER_MESSAGE
    else
      dispute.resolution_comment = TICKET_CONVERSION_CUSTOMER_MESSAGE
    end

    dispute.save

    dispute.dispute_entries.each do |d_entry|
      d_entry.status = DisputeEntry::STATUS_RESOLVED
      d_entry.resolution = DisputeEntry::STATUS_RESOLVED_INVALID
      if auto_resolve.present?
        if dispute.submitter_type == SUBMITTER_TYPE_CUSTOMER
          d_entry.resolution_comment = AUTO_TICKET_CONVERSION_CUSTOMER_MESSAGE
        else
          d_entry.resolution_comment = AUTO_NC_TICKET_CONVERSION_CUSTOMER_MESSAGE
        end

      else
        d_entry.resolution_comment = TICKET_CONVERSION_CUSTOMER_MESSAGE
      end

      d_entry.save
    end

    message = Bridge::DisputeEntryUpdateStatusEvent.new
    message.post_entries(dispute.dispute_entries)

    return true
  end


  def self.build_ips_bug(bugzilla_rest_session, new_entries_ips, new_entries_urls, problem, original_bug_id)
    summary = "New Web Reputation Dispute generated at #{DateTime.now.utc.strftime("%Y-%m-%d %H:%M")}"

    full_description = <<~HEREDOC
      IPs: #{new_entries_ips.keys}
      URIs: #{new_entries_urls.keys}
      Problem Summary: #{problem}
    HEREDOC

    bug_attrs = Bug.build_bugzilla_attrs(summary, full_description)
    logger.debug "Creating bugzilla bug"

    research_bug_proxy = bugzilla_rest_session.create_bug(bug_attrs)

    linked_bug_proxy = bugzilla_rest_session.build_bug({id: original_bug_id, depends_on:[research_bug_proxy.id]})
    linked_bug_proxy.save!

    new_bug = Bug.build_local_research_bug_from_bugzilla_bug(research_bug_proxy)

    research_bug_proxy

  end

  def get_email_meta_data

    response = {}
    if self.meta_data.present?
      begin
        meta_data = JSON.parse(self.meta_data).deep_symbolize_keys

        meta_cc = nil
        if meta_data[:ticket].present? && meta_data[:ticket][:cc].present?
          meta_cc = meta_data[:ticket][:cc]
        end

        if meta_data[:entry].present? && meta_data[:entry][:cc].present?
          meta_cc = meta_data[:entry][:cc]
        end

        if meta_cc.present?
          response[:cc] = meta_cc
        end
      rescue
        response = {}
      end

    end

    response

  end


  def determine_platform
    if self.platform_id.present?
      return (self.platform.public_name rescue 'No Data')
    end
    if self.dispute_entries.present?
      if self.dispute_entries.first.platform_id.present?
        return self.dispute_entries.map{|d_e| d_e.product_platform.public_name rescue 'No Data'}.uniq.join(",")
      end
    end
    return nil
  end

  def determine_platform_record
    if self.platform_id.present?
      return Platform.find(self.platform_id) rescue nil
    end
    return nil
  end
end

