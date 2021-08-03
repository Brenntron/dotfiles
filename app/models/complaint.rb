class Complaint < ApplicationRecord
  belongs_to :customer, optional: true
  has_many :complaint_entries, dependent: :restrict_with_exception
  has_and_belongs_to_many :complaint_tags, dependent: :destroy
  belongs_to :platform, optional: true
  has_paper_trail on: [:update], ignore: [:updated_at]

  delegate :name, :company_name, to: :customer, allow_nil: true, prefix: true

  RESOLUTION_FIXED                      = 'FIXED'
  RESOLUTION_INVALID                    = 'INVALID'
  RESOLUTION_UNCHANGED                  = 'UNCHANGED'
  RESOLUTION_DUPLICATE                  = 'DUPLICATE'

  NEW = 'NEW'
  RESOLVED = 'RESOLVED'
  ASSIGNED = 'ASSIGNED'
  ACTIVE = 'ACTIVE'
  COMPLETED = 'COMPLETED'
  PENDING = 'PENDING'
  DUPLICATE = "DUPLICATE"
  REOPENED = "REOPENED"

  TI_NEW = 'PENDING'
  TI_RESOLVED = 'RESOLVED'

  AC_SUCCESS = 'CREATE_ACK'
  AC_FAILED = 'CREATE_FAILED'
  AC_PENDING = 'CREATE_PENDING'

  SUBMITTER_TYPE_CUSTOMER = "CUSTOMER"
  SUBMITTER_TYPE_NONCUSTOMER = "NON-CUSTOMER"

  TI_CHANNEL = 'talosintel'
  INT_CHANNEL = 'internal'
  WBNP_CHANNEL = 'wbnp'

  SOURCE_RULEUI = "RuleUI"

  MAIN_WEBCAT_MANAGER_CONTACT = "admatter"

  TICKET_CONVERSION_CUSTOMER_MESSAGE = "Thank you for your request; this has now been forwarded to the team responsible for Web and Email reputation. AUP categories are not applied to URLs that are primarily malicious in nature but may be applied in cases where a domain has been compromised or in cases of a web reputation false positive - these updates may take several hours to propagate. A new Web and Email Reputation ticket has been created on your behalf and should be visible in your ticket submission queue. Please see all future updates regarding this request on the new ticket.

For future web and email reputation requests, please open a web categorization ticket using the \"Web & Email\" form: https://talosintelligence.com/reputation_center/support#reputation
"

  scope :active_count , -> {where(status:ACTIVE).count}
  scope :completed_count , -> {where(status:COMPLETED).count}
  scope :new_count , -> {where(status:NEW).count}
  scope :overdue_count , -> {where("created_at < ?",Time.now - 12.hours).where.not(status:COMPLETED).count}
  scope :open_comps, -> { where.not(status: COMPLETED) }

  scope :by_guest, -> { joins(:customer).where(customers: {company_id: Company.guest.id}) }
  scope :by_cust, -> { joins(:customer).where.not(customers: {company_id: Company.guest.id}) }

  scope :from_ti, -> { includes(:complaint_entries).where(channel: TI_CHANNEL) }
  scope :from_wbnp, -> { includes(:complaint_entries).where(channel: WBNP_CHANNEL) }
  scope :from_int, -> { includes(:complaint_entries).where(channel: INT_CHANNEL) }

  def set_status(new_status)
    status_list = complaint_entries.map{|entry| entry.status}
    case new_status
      when NEW
        update!(status: status_list.any? {|item| [ASSIGNED,PENDING,COMPLETED].include? item}? ACTIVE: NEW)
      when ASSIGNED || PENDING
        update!(status:ACTIVE)
      when COMPLETED
        update!(status: status_list.any? {|item| [ASSIGNED,PENDING,NEW].include? item}? ACTIVE: COMPLETED)
    end
  end

  def self.can_visit_url?(url)
    begin
    request = HTTPI::Request.new(url: url)
    response = HTTPI.get(request)
    if response.code == 301
      redirected = Complaint.can_visit_url?(response.headers['Location'])
    end
    if ['SAMEORIGIN'].include?(response.headers['X-Frame-Options'])
      return {status: 403, error: "cannot load page, X-Frame-Options set to #{response.headers['X-Frame-Options']}" }.to_json
    end

    return redirected || { status: "SUCCESS" }.to_json

    rescue Curl::Err::HostResolutionError => e
      return {status: 404, error: e.message}.to_json
    end
  end

  def self.parse_url(url)
    if !url.starts_with?("http")
      url = "http://" + url
    end
    url = URI.escape(url)
    uri = URI.parse(URI.parse(url).scheme.nil? ? "http://#{url}" : url)
    domain = PublicSuffix.parse(uri.host, :ignore_private => true)
    subdomain = uri.host.gsub(/\A[0-9]*www[0-9]*\./, '').gsub(Regexp.new("\\.?#{domain.domain}$"), '')

    {
        subdomain: subdomain,
        domain: domain.domain,
        path: uri.path
    }
  end

  def self.is_possible_company_duplicate(complaint, entry, entry_type)
    company_id = complaint.customer.company.id
    possible_duplicates = false
    candidates = Complaint.includes(:customer).includes(:complaint_entries).where("complaints.status != '#{RESOLVED}'").where(:customers => {:company_id => company_id}, :complaint_entries => {:entry_type => entry_type})

    if candidates.blank?
      return false
    end
    complaint.reload
    current_complaint_entries = complaint.complaint_entries

    candidates.each do |candidate|
      if entry_type == "IP"
        possible_duplicates = (candidate.complaint_entries - current_complaint_entries).any? {|complaint_entry| complaint_entry.ip_address == entry}
        if possible_duplicates == true
          return true
        end
      end

      if entry_type == "URI/DOMAIN"
        possible_duplicates = (candidate.complaint_entries - current_complaint_entries).any? {|complaint_entry| complaint_entry.uri == entry}
        if possible_duplicates == true
          return true
        end
      end

    end

    return possible_duplicates.present?

  end


  def self.commit_without_complaint(ip_or_uri:, category_ids_string:, category_names_string:, description:, user:, bugzilla_rest_session:)
    # check to see if URL is in Top URLS
    top_url = Wbrs::TopUrl.check_urls([ip_or_uri]).first.is_important
    if top_url
      #create a complaint/complaint entry and set to pending
      Complaint.create_action(bugzilla_rest_session, ip_or_uri, description, nil, nil, nil, PENDING, category_names_string, user)
    else
      # Look for existing prefix
      existing_prefix = Wbrs::Prefix.where({urls: [ip_or_uri]})

      category_ids_array = Wbrs::Category.get_category_ids(category_ids_string.split(','))

      if existing_prefix.present?
        prefix_object = Wbrs::Prefix.new
        prefix_object.set_categories(category_ids_array, prefix_id: existing_prefix[0].prefix_id, user: user, description: description)
      else
        Wbrs::Prefix.create_from_url(url: ip_or_uri, categories: category_ids_array, user: user, description: description)
      end
    end
  end


  def self.is_possible_customer_duplicate?(complaint, new_entries_ips, new_entries_urls)

    new_uris = new_entries_urls.keys.sort
    new_ips = new_entries_ips.keys.sort

    response = {}
    possibles = complaint.customer.complaints.where.not(status: [ RESOLVED, DUPLICATE, COMPLETED ]) rescue []
    candidates = []

    possibles.each do |poss|

      ips = poss.complaint_entries.select{ |entry| entry.entry_type == "IP"}.pluck(:ip_address).sort
      uris = poss.complaint_entries.select{ |entry| entry.entry_type == "URI/DOMAIN"}.pluck(:uri).sort

      if ips == new_ips && uris == new_uris
        candidates << poss
      end
    end

    if candidates.present?
      best_candidate = candidates.sort_by {|candidate| candidate.id}.first
      response[:authority] = best_candidate
      response[:is_dupe] = true
    else
      response[:is_dupe] = false
    end

    response

  end

  def self.manage_duplicate_complaint(complaint, authority_complaint, new_entries_ips, new_entries_urls, source_key)
    resolved_at = Time.now
    complaint.status = RESOLVED
    complaint.resolution = RESOLUTION_DUPLICATE
    complaint.save

    return_payload = {}

    new_entries_ips.each do |ip, entry|
      new_payload_item = {}
      new_payload_item[:resolution_message] = "This is a duplicate of a currently active ticket."
      new_payload_item[:resolution] = "DUPLICATE"
      new_payload_item[:status] = TI_RESOLVED
      new_payload_item[:sugg_type] = entry["cat_sugg"]&.join(', ')
      return_payload[ip] = new_payload_item
      new_complaint_entry = ComplaintEntry.new
      new_complaint_entry.complaint_id = complaint.id
      new_complaint_entry.ip_address = ip
      new_complaint_entry.entry_type = "IP"
      new_complaint_entry.status = ComplaintEntry::RESOLVED
      new_complaint_entry.resolution = ComplaintEntry::STATUS_RESOLVED_DUPLICATE
      new_complaint_entry.case_resolved_at = resolved_at
      new_complaint_entry.save
      create_complaint_entry_credit(new_complaint_entry)
    end
    new_entries_urls.each do |url, entry|
      new_payload_item = {}
      new_payload_item[:resolution_message] = "This is a duplicate of a currently active ticket."
      new_payload_item[:resolution] = "DUPLICATE"
      new_payload_item[:status] = TI_RESOLVED
      new_payload_item[:sugg_type] = entry["cat_sugg"]&.join(', ')
      return_payload[url] = new_payload_item
      url_parts = parse_url(url)
      new_complaint_entry = ComplaintEntry.new
      new_complaint_entry.complaint_id = complaint.id
      new_complaint_entry.uri = url
      new_complaint_entry.entry_type = "URI/DOMAIN"
      new_complaint_entry.status = ComplaintEntry::RESOLVED
      new_complaint_entry.resolution = ComplaintEntry::STATUS_RESOLVED_DUPLICATE
      new_complaint_entry.case_resolved_at = resolved_at
      new_complaint_entry.subdomain = url_parts[:subdomain]
      new_complaint_entry.domain = url_parts[:domain]
      new_complaint_entry.path = url_parts[:path]
      new_complaint_entry.save
      create_complaint_entry_credit(new_complaint_entry)
    end

    conn = ::Bridge::DisputeCreatedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: source_key, ac_id: complaint.id)
    conn.post(return_payload, "")

  end

  def self.create_complaint_entry_credit(entry)
    WebcatCredits::ComplaintEntries::CreditProcessor.new(nil, entry).process
  end

  def build_ti_payload
    payload = {}

    complaint_entries.each do |entry|
      new_payload_item = {}
      new_payload_item[:sugg_type] = entry.suggested_disposition
      new_payload_item[:status] = entry.status
      new_payload_item[:resolution_message] = entry.resolution_comment
      new_payload_item[:resolution] = entry.resolution
      new_payload_item[:company_dup] = Complaint.is_possible_company_duplicate(self, entry.hostlookup, entry.entry_type)

      payload[entry.hostlookup] = new_payload_item
      payload[entry.hostlookup]['sugg_type'] = entry.suggested_disposition
    end

    payload
  end

  def self.process_bridge_payload(message_payload)

    begin

      record_exists = Complaint.where(:ticket_source_key => message_payload["source_key"]).first

      if record_exists.present?
        return_payload = record_exists.build_ti_payload
        conn = ::Bridge::ComplaintCreatedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: message_payload["source_key"], ac_id: record_exists.id)
        return conn.post(return_payload)
      end

      user = User.where(cvs_username:"vrtincom").first
      guest = Company.where(:name => "Guest").first
      #TODO: this should be put in a params method
      new_entries_ips = message_payload["payload"]["investigate_ips"]
      new_entries_urls = message_payload["payload"]["investigate_urls"]

      return_payload = {}

      #create an escalations IP/DOMAIN bugzilla bug here and transfer id to new dispute

      summary = "New Web Category Complaint generated at #{DateTime.now.utc.strftime("%Y-%m-%d %H:%M")}"

      full_description = <<~HEREDOC
          IPs: #{new_entries_ips.keys.join(', ')}
          URIs: #{new_entries_urls.keys.join(', ')}
          Problem Summary: #{message_payload["payload"]["problem"]}
        HEREDOC

      bug_attrs = {
          'product' => 'Escalations Console',
          'component' => 'Categorization',
          'summary' => summary,
          'version' => 'unspecified', #self.version,
          'description' => full_description,
          'priority' => 'Unspecified',
          'classification' => 'unclassified',
      }

      bugzilla_rest_session = message_payload[:bugzilla_rest_session]
      bug_proxy = bugzilla_rest_session.create_bug(bug_attrs, assigned_user: user)

      internal_comment = nil

      if message_payload["payload"]["product_platform"].present?
        platform = Platform.find(message_payload["payload"]["product_platform"].to_i) rescue nil
      end

      new_complaint = Complaint.new

      new_complaint.bridge_packet = message_payload.to_json

      new_complaint.submission_type = message_payload["payload"]["submission_type"]
      new_complaint.id = bug_proxy.id
      new_complaint.meta_data = message_payload["payload"]["meta_data"]
      new_complaint.description = message_payload["payload"]["problem"]
      new_complaint.ticket_source_key = message_payload["source_key"]
      new_complaint.ticket_source = message_payload["source"].blank? ? "talos-intelligence" : message_payload["source"]
      new_complaint.ticket_source_type = message_payload["source_type"]
      customer = Customer.process_and_get_customer(message_payload)
      new_complaint.customer_id = customer&.id
      new_complaint.status = NEW
      new_complaint.channel = TI_CHANNEL

      new_complaint.platform_id = platform.id unless platform.blank?
      new_complaint.product_platform = message_payload["payload"]["product_platform"] unless (message_payload["payload"]["product_platform"].blank? || message_payload["payload"]["product_platform"].kind_of?(Integer))

      new_complaint.product_version = message_payload["payload"]["product_version"] unless message_payload["payload"]["product_version"].blank?
      new_complaint.in_network = message_payload["payload"]["network"] unless message_payload["payload"]["network"].blank?

      new_complaint.submitter_type = (new_complaint.customer.nil? || new_complaint.customer&.company_id == guest.id) ? SUBMITTER_TYPE_NONCUSTOMER : SUBMITTER_TYPE_CUSTOMER
      if message_payload["payload"]["api_customer"].present? && message_payload["payload"]["api_customer"] == true
        new_complaint.submitter_type = SUBMITTER_TYPE_CUSTOMER
      end
      if message_payload["payload"]["network"].present? && message_payload["payload"]["network"] == true
        ips_bug_proxy= build_ips_bug(bugzilla_rest_session, new_entries_ips, new_entries_urls, message_payload["payload"]["problem"], bug_proxy.id)

        internal_comment = "Complaint is [in network], IPS bugzilla bug created. Reference Bugzilla ID: #{ips_bug_proxy.id}"

      end

      new_complaint.save!

      max_wait_for_job = 60 #seconds

      ActiveRecord::Base.transaction do
        response = is_possible_customer_duplicate?(new_complaint, new_entries_ips, new_entries_urls)

        if response[:is_dupe] == true
          begin
            manage_duplicate_complaint(new_complaint, response[:authority], new_entries_ips, new_entries_urls, message_payload["source_key"] )
            return
          rescue => e
            Rails.logger.error e
            Rails.logger.error e.backtrace.join("\n")

            conn = ::Bridge::ComplaintFailedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: message_payload["source_key"])
            conn.post
            return
          end

        end
      end

      ActiveRecord::Base.transaction do
        #########################################################################################
        new_entries_ips.each do |key, entry|
          if entry['wbrs']['platform'].present?
            entry_platform = Platform.find(entry['wbrs']['platform'].to_i) rescue nil
          end

          new_complaint_entry = ComplaintEntry.new
          new_complaint_entry.complaint_id = new_complaint.id
          new_complaint_entry.user_id = user.id
          new_complaint_entry.ip_address = key
          new_complaint_entry.wbrs_score = entry[:wbrs]["WBRS_SCORE"]
          new_complaint_entry.entry_type = "IP"
          new_complaint_entry.suggested_disposition = entry['wbrs']["cat_sugg"].join(",") unless entry['wbrs']['cat_sugg'].blank?
          new_complaint_entry.platform = entry['wbrs']['platform'] if (entry['wbrs']['platform'].present? && !entry['wbrs']['platform'].kind_of?(Integer))
          new_complaint_entry.platform_id = entry_platform.id unless entry_platform.blank?
          new_complaint_entry.status = ComplaintEntry::NEW
          if internal_comment.present?
            new_complaint_entry.internal_comment = internal_comment
          end
          new_complaint_entry.url_primary_category = entry["current_cat"] unless entry['current_cat'].blank?
          new_complaint_entry.save!

        end

        #########################################################################################
        new_entries_urls.each do |key, entry|
          if entry['platform'].present?
            entry_platform = Platform.find(entry['platform'].to_i) rescue nil
          end

          new_complaint_entry = ComplaintEntry.new
          new_complaint_entry.complaint_id = new_complaint.id
          new_complaint_entry.user_id = user.id
          new_complaint_entry.uri = key.gsub(/\Ahttp[s]*\:\/\//, '').gsub(/\A[0-9]*www[0-9]*\./, '')
          new_complaint_entry.entry_type = "URI/DOMAIN"
          new_complaint_entry.wbrs_score = entry['WBRS_SCORE']
          new_complaint_entry.suggested_disposition = entry["cat_sugg"].join(",") unless entry['cat_sugg'].blank?
          new_complaint_entry.platform = entry["platform"] if (entry["platform"].present? && !entry['platform'].kind_of?(Integer))
          new_complaint_entry.platform_id = entry_platform.id unless entry_platform.blank?
          new_complaint_entry.status = ComplaintEntry::NEW
          new_complaint_entry.url_primary_category = entry["current_cat"] unless entry['current_cat'].blank?
          #lets query the top url API endpoint to determine if this is an important site or not
          # but you better believe i dont trust this API so we have some checks to ensure the entry gets created

          if internal_comment.present?
            new_complaint_entry.internal_comment = internal_comment
          end

          new_complaint_entry.save!

        end
      end

      new_complaint.reload

      begin
        new_complaint.complaint_entries.each do |complaint_entry|
          prefix_response = Wbrs::Prefix.where({:urls => [complaint_entry.hostlookup]})

          if !prefix_response.first&.is_active?
            complaint_entry.url_primary_category = nil
          end

          importance = Wbrs::TopUrl.check_urls([complaint_entry.hostlookup]).first.is_important
          complaint_entry.is_important = importance if !!importance == importance

          new_payload_item = {}
          new_payload_item[:sugg_type] = complaint_entry.suggested_disposition unless complaint_entry.suggested_disposition.blank?
          new_payload_item[:status] = TI_NEW
          new_payload_item[:resolution_message] = ""
          new_payload_item[:resolution] = ""

          if complaint_entry.entry_type == "IP"
            new_payload_item[:company_dup] = is_possible_company_duplicate(new_complaint, complaint_entry.hostlookup, "IP")
            return_payload[complaint_entry.hostlookup] = new_payload_item

          end

          if complaint_entry.entry_type == "URI/DOMAIN"
            url_parts = parse_url(complaint_entry.hostlookup)
            complaint_entry.subdomain = url_parts[:subdomain]
            complaint_entry.domain = url_parts[:domain]
            complaint_entry.path = url_parts[:path]

            new_payload_item[:company_dup] = is_possible_company_duplicate(new_complaint, complaint_entry.hostlookup, "URI/DOMAIN")
            return_payload[complaint_entry.hostlookup] = new_payload_item
          end

          complaint_entry.save

          ComplaintEntryPreload.generate_preload_from_complaint_entry(complaint_entry)

          begin
            # if we are generating a new screenshot then we need to remove the old one
            unless complaint_entry.complaint_entry_screenshot.nil?
              ComplaintEntryScreenshot.find(complaint_entry.complaint_entry_screenshot.id).delete
            end
            ces = ComplaintEntryScreenshot.create(complaint_entry_id: complaint_entry.id )
            # CALL SCREENSHOT BACKGROUND JOB! with ces.id and new_complaint_entry.hostlookup
            ces.grab_screenshot
          rescue Exception => e
            Rails.logger.error("#{e.message}")
            ces = ComplaintEntryScreenshot.new
            ces.error_message = e.message
            ces.complaint_entry_id = complaint_entry.id
            open("app/assets/images/failed_screenshot.jpg") do |f|
              ces.screenshot = f.read
            end
            ces.save!
          end

        end
      rescue => e
        Rails.logger.error e
        Rails.logger.error e.backtrace.join("\n")
      end

      new_complaint.reload
      if new_complaint.complaint_entries.blank?
        new_complaint.destroy

        conn = ::Bridge::ComplaintFailedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: message_payload["source_key"])
        conn.post
        return
      else
        conn = ::Bridge::ComplaintCreatedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: message_payload["source_key"], ac_id: new_complaint.id)
        conn.post(return_payload)
      end

      #################################################################################################
        #change this
        #return_message = {
        #    "envelope":
        #        {
        #            "channel": "ticket-acknowledge",
        #            "addressee": "talos-intelligence",
        #            "sender": "analyst-console"
        #        },
        #    "message": {"source_key":params["source_key"],"ac_status":"CREATE_ACK", "ticket_entries": return_payload, "case_email": nil}
        #}

    rescue Exception => e
      Rails.logger.error "Complaint failed to save, backing out all DB changes."
      Rails.logger.error $!
      Rails.logger.error $!.backtrace.join("\n")
      new_complaint.reload
      new_complaint.complaint_entries.destroy_all
      new_complaint.destroy

      conn = ::Bridge::ComplaintFailedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: message_payload["source_key"])
      conn.post
    end
  end

  def self.get_latest_wbnp_complaints(skip_thread = false)
    
    max_attempts = 3

    #status reason
    #attempts

    last_report = WbnpReport.order("id DESC").first
    if last_report.present? && last_report.status == WbnpReport::ACTIVE
      if last_report.attempts < max_attempts
        last_report.attempts += 1
        last_report.status_message = "Attempting to finish a running report, #{last_report.attempts} tries out of #{max_attempts}"
        last_report.save
        return last_report
      end

      if last_report.attempts >= max_attempts
        last_report.status = WbnpReport::ERROR
        last_report.status_message = "waited #{last_report.attempts} times for pull to complete, closing report and starting a new one"
        last_report.save
      end
    end


    new_report = WbnpReport.new

    all_complaints = Wbrs::RuleUiComplaint.where({:add_channels => [WBNP_CHANNEL], :statuses => ['new']})["data"]

    logger_token = SecureRandom.uuid
    new_report.notes = ""
    new_report.cases_imported = 0
    new_report.cases_failed = 0
    new_report.attempts = 0
    new_report.status_message = "Starting new pull."
    new_report.total_new_cases = all_complaints.size
    new_report.status = WbnpReport::ACTIVE
    new_report.notes += "logger_token: #{logger_token} <br />"
    new_report.save
    if skip_thread == true
      start_wbnp_pull(new_report.id, logger_token)
    else
      Thread.new do
        start_wbnp_pull(new_report.id, logger_token)
      end
    end
    new_report

  end

  class << self

    def kick_off_wbnp_pull(new_report_id, logger_token)
      start_wbnp_pull(new_report_id, logger_token)
    end

    #handle_asynchronously :kick_off_wbnp_pull, :queue => "wbnp_pull", :priority => 2

    def start_wbnp_pull(new_report_id, logger_token)

      new_report = WbnpReport.find(new_report_id)
      begin

        platform = Platform.where("internal_name like '%wsa%'").first

        all_complaints = Wbrs::RuleUiComplaint.where({:add_channels => [WBNP_CHANNEL], :statuses => ['new']})["data"]
        total_entries = all_complaints.size
        entry_num = 1
        bugzilla_rest_session = BugzillaRest::Session.default_session

        all_complaints.each do |new_ui_complaint|

          if new_ui_complaint['add_channel'] == WBNP_CHANNEL
            begin
              uri = compile_parts_to_uri(new_ui_complaint)
              new_report.notes += "<br />working (#{entry_num}/#{total_entries}) uri: #{uri}."
              new_report.save
              pass = validate_url(uri, new_ui_complaint)
              new_report.notes += "<br />validation pass: #{pass.to_s}."

              new_report.notes += "<br />checking for duplicate entry: uri: #{uri}."
              exists = Complaint.where(:ticket_source_key => new_ui_complaint["complaint_id"], :channel => WBNP_CHANNEL).first
              if exists.present?
                new_report.notes += "<br />record exists for uri: #{uri} with source id: #{new_ui_complaint["complaint_id"]}"
                new_report.save
                next
              else
                new_report.notes += "<br />no duplicate record exists for uri: #{uri} with source id: #{new_ui_complaint["complaint_id"]}"
              end

              new_report.save



              if pass
                rule_ui_wbnp_create_action(uri, new_ui_complaint, new_report, logger_token, platform, bugzilla_rest_session: bugzilla_rest_session)
              else
                reject_complaint(uri, new_ui_complaint, new_report, logger_token)
              end
            rescue => e

              new_report.cases_failed += 1
              new_report.notes += "<br />SWP uri: #{new_ui_complaint.inspect} | log token: #{logger_token} | failure: #{e.message}<br />"

              new_report.save

              Rails.logger.error "#{logger_token} | " + e.message
              Rails.logger.error "#{logger_token} | " + e.backtrace.join("\n")
            end
            entry_num += 1
          end
        end

        new_report.status = WbnpReport::COMPLETE
        new_report.save
      rescue => e

        new_report.status = WbnpReport::ERROR
        new_report.notes += "<br />--------<br />token: #{logger_token} Pull suddenly ended with error: #{e.message}<br />"
        new_report.save

        Rails.logger.error "#{logger_token} | " + e.message
        Rails.logger.error "#{logger_token} | " + e.backtrace.join("\n")
      end

    end


  end

  def self.compile_parts_to_uri(parts)
    subdomain = ""
    if parts["subdomain"].present?
      subdomain = "#{parts["subdomain"]}."
      subdomain = subdomain.gsub(/\A[0-9]*www[0-9]*\./, '')
    end
    uri = "#{subdomain}#{parts["domain"]}#{parts["path"]}"

    URI.escape(uri)
  end

  def self.validate_url(uri, new_ui_complaint)
    begin
      URI.parse(uri.strip)

      first_test_url = URI.escape(uri)
      first_test_uri = URI.parse(URI.parse(first_test_url).scheme.nil? ? "http://#{first_test_url}" : first_test_url)
      first_test_domain = PublicSuffix.parse(first_test_uri.host, :ignore_private => true)
      first_test_uri.host.gsub(/\A[0-9]*www[0-9]*\./, '').gsub(Regexp.new("\\.?#{first_test_domain.domain}$"), '')

      if new_ui_complaint["protocol"].present?
        test_uri = "#{new_ui_complaint["protocol"]}://#{uri.strip}"
      else
        test_uri = "http://#{uri.strip}"
      end
      clean_url = Addressable::URI.parse(test_uri)
      if clean_url.host.blank? || clean_url.host == "http.com" || clean_url.host == "https.com"
        valid = false
      else
        valid = true
      end

    rescue
      valid = false
    end

    valid
  end

  def self.reject_complaint(uri, new_ui_complaint, new_report, logger_token)

    new_report.notes += "rejecting uri: #{uri}"
    new_report.save

    complaint_id = new_ui_complaint["complaint_id"]

    params = {:complaint_id => complaint_id, :new_tag => "invalid"}
    response = Wbrs::RuleUiComplaint.tag_complaint(params)
    if response == "Complaint's tag was updated successfully."
      new_report.notes += "<br />uri tagged as invalid on ruleAPI"
    else
      #{"data"=>[]} might usually mean HTTP response 400 Complaint with ID [some id] not found.
      new_report.notes += "<br />uri was not rejected on ruleAPI (error) | log token #{logger_token}"
      Rails.logger.error "#{logger_token} | response from tagging for uri: #{uri} | " + response
    end
    begin
      response = Wbrs::RuleUiComplaint.assign_tickets({:complaint_ids => [complaint_id], :user => "admatter"})
      if response["assigned"] == [complaint_id]
        new_report.notes += "<br />invalid uri assigned(rejected) on ruleAPI"
      else
        new_report.notes += "<br />something went wrong with rejection assignment: #{response.to_s}"
      end

      new_report.save
    rescue => e
      new_report.notes += "<br />--------<br />Exception when assigning ticket #{complaint_id} to admatter - error: #{e.message}<br />"

      new_report.save

      Rails.logger.error "#{logger_token} | " + e.message
      Rails.logger.error "#{logger_token} | " + e.backtrace.join("\n")
    end

    new_report.cases_failed += 1

    new_report.save
  end

  def self.rule_ui_wbnp_create_action(uri, rule_ui_complaint, wbnp_report, logger_token, platform, bugzilla_rest_session:)
    #"#{{"add_channel"=>"wbnp", "comment"=>"", "complaint_id"=>105, "complaint_type"=>"unknown", "customer_name"=>"ORANGE BUSINES SERVICES", "description"=>"",
    # "domain"=>"fmp-usmba.ac.ma", "path"=>"/cdim/mediatheque/e_theses/257-16.pdf", "port"=>0, "protocol"=>"http", "region"=>"", "resolution"=>nil, "state"=>"new",
    # "subdomain"=>"scolarite", "tag"=>nil, "url_query_string"=>"", "when_added"=>"Thu, 30 Aug 2018 15:00:05 GMT", "when_last_updated"=>"Thu, 30 Aug 2018 15:00:05 GMT",
    # "who_updated"=>""}}"

    description = "WBNP Sourced Complaint"


    #user = User.where(cvs_username:"vrtincom").first
    user = User.vrtincoming

    summary = "New Web Category Complaint generated at #{DateTime.now.utc.strftime("%Y-%m-%d %H:%M")}"

    full_description = %Q{
          IPs/URIs: #{uri}
          Problem Summary: #{description}
    }

    bug_attrs = {
        'product' => 'Escalations Console',
        'component' => 'Categorization',
        'summary' => summary,
        'version' => 'unspecified', #self.version,
        'description' => full_description,
        'priority' => 'Unspecified',
        'classification' => 'unclassified',
    }
    Rails.logger.error "#{logger_token} building bugzilla bug for uri: #{uri}\n"
    bug_proxy = bugzilla_rest_session.create_bug(bug_attrs)

    cust = Customer.customer_from_ruleui(rule_ui_complaint)

    new_complaint = Complaint.create(id: bug_proxy.id,
                                     description: description,
                                     customer_id: cust ? cust.id : nil,
                                     status: NEW,
                                     channel: WBNP_CHANNEL,
                                     ticket_source_type: 'Complaint',
                                     ticket_source: Complaint::SOURCE_RULEUI,
                                     ticket_source_key: rule_ui_complaint["complaint_id"])
    Rails.logger.error "#{logger_token} built and saved bugzilla bug for uri: #{uri}\n"
    begin
      Rails.logger.error "#{logger_token} getting category data for uri: #{uri}\n"
      category_data = ComplaintEntry.get_category_data(uri)
    rescue
      category_data = []
    end

    if category_data.empty?
      primary_category = nil
    else
      primary_category = category_data[:category_names][0]
    end
    begin
      Rails.logger.error "#{logger_token} building complaint entry for uri: #{uri}\n"
      ComplaintEntry.create_wbnp_complaint_entry(new_complaint, uri, rule_ui_complaint, User.where(display_name:"Vrt Incoming").first, ComplaintEntry::NEW, primary_category, logger_token, platform)
      Rails.logger.error "#{logger_token} complaint entry build complete for uri: #{uri}\n"

      begin
        response = Wbrs::RuleUiComplaint.assign_tickets({:complaint_ids => [rule_ui_complaint["complaint_id"]], :user => "admatter"})
        if response["assigned"] == [rule_ui_complaint["complaint_id"]]
          wbnp_report.notes += "<br />valid uri assigned on ruleAPI"
        else
          wbnp_report.notes += "<br />something went wrong with assignment: #{response.to_s}"
        end

        wbnp_report.save
      rescue => e
        wbnp_report.notes += "<br />--------<br />Exception when assigning ticket #{complaint_id} to admatter - error: #{e.message}<br />"

        wbnp_report.save

        Rails.logger.error "#{logger_token} | " + e.message
        Rails.logger.error "#{logger_token} | " + e.backtrace.join("\n")
      end

      wbnp_report.cases_imported += 1

    rescue Exception => e
      wbnp_report.cases_failed += 1
      wbnp_report.notes += "<br />RUWCA uri: #{uri} | log token: #{logger_token} | failure: #{e.message}<br />"

      Rails.logger.error "#{logger_token} | " + e.message
      Rails.logger.error "#{logger_token} | " + e.backtrace.join("\n")
    end

    wbnp_report.save
  end

  def self.create_action(bugzilla_rest_session, ips_urls, description, customer, tags, platform, status=NEW, categories = nil, user_email = nil)

    summary = "New Web Category Complaint generated at #{DateTime.now.utc.strftime("%Y-%m-%d %H:%M")}"

    full_description = <<~HEREDOC
          IPs/URIs: #{ips_urls}
          Problem Summary: #{description}
    HEREDOC
    bug_attrs = {
        'product' => 'Escalations Console',
        'component' => 'Categorization',
        'summary' => summary,
        'version' => 'unspecified', #self.version,
        'description' => full_description,
        'priority' => 'Unspecified',
        'classification' => 'unclassified',
    }

    bug_proxy = bugzilla_rest_session.create_bug(bug_attrs)


    cust = find_customer(customer) if customer
    platform_record = Platform.find_by_public_name(platform) if platform
    new_complaint = Complaint.create(id: bug_proxy.id,
                                     description: description,
                                     customer_id: cust&.id,
                                     platform_id: platform_record&.id,
                                     status: status,
                                     channel: INT_CHANNEL)


    handle_tags(new_complaint, tags) if tags

    user = if user_email
      User.find_by_email(user_email)
    else
      User.where(display_name:"Vrt Incoming").first
    end

    ips_urls.split(' ').each do |ip_url|
      ComplaintEntry.create_complaint_entry(new_complaint, ip_url, platform_record, user, status, categories)
    end

    bug_proxy
  end

  def self.find_customer(customer)
    email = customer.split(':').last
    Customer.find_by_email(email)
  end

  def self.handle_tags(complaint, tags)
    tags.each do |tag|
      new_tag = ComplaintTag.find_or_create_by(name: tag)
      complaint.complaint_tags << new_tag
    end
  end

  def self.sync_all
    AdminTask.execute_task(:sync_complaints_with_ti, {})
  end

  def manual_sync
    message = Bridge::ComplaintUpdateStatusEvent.new
    message.post_complaint(self)
  end

  def self.convert_to_dispute(params, current_user)
    platform_id = nil
    complaint = Complaint.find(params[:complaint_id])
    suggested_disposition_entries = params[:suggested_dispositions]
    package = {}
    package[:entries] = []
    package[:convert_to] = "Dispute"
    package[:submission_type] = params[:submission_type]
    package[:email] = complaint&.customer&.email
    package[:name] = complaint&.customer&.name
    package[:company_name] = complaint&.customer&.company&.name
    package[:internal_message] = params[:summary] + " | " + "original analyst console webcat ticket: #{complaint.id.to_s}"
    suggested_disposition_entries.each do |sugg|
      if complaint.platform_id.present?
        platform_id = complaint.platform_id unless complaint.platform_id.blank?
      else
        comp_entry = complaint.complaint_entries.select {|c| c.hostlookup == sugg[:entry]}.first
        if comp_entry.present?
          platform_id = comp_entry.platform_id unless comp_entry.platform_id.blank?
        end
      end

      entry = {}
      entry[:entry] = sugg[:entry]
      #needs to be either 'fp' or 'fn'
      entry[:suggested_disposition] = sugg[:suggested_disposition]
      entry[:platform_id] = platform_id
      package[:entries] << entry
    end

    conn = ::Bridge::TicketConversionEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: complaint.ticket_source_key, ac_id: complaint.id)
    conn.post(package)

    #set status and resolution here with a message
    #send update to bridge

    complaint.status = Complaint::COMPLETED
    complaint.resolution_comment = TICKET_CONVERSION_CUSTOMER_MESSAGE
    complaint.save

    complaint.complaint_entries.each do |c_entry|
      if c_entry.internal_comment.blank?
        c_entry.internal_comment = ""
      end
      if c_entry.status != ComplaintEntry::STATUS_COMPLETED
        c_entry.status = ComplaintEntry::STATUS_COMPLETED
        c_entry.resolution = ComplaintEntry::STATUS_RESOLVED_FIXED_INVALID
        c_entry.resolution_comment = TICKET_CONVERSION_CUSTOMER_MESSAGE
        c_entry.internal_comment += " | User: #{current_user&.cvs_username} converted SDO ticket to webrep TE ticket on #{Time.now.to_s}"
        c_entry.save
      end
    end

    bridge_message = Bridge::ComplaintUpdateStatusEvent.new
    bridge_message.post_complaint(complaint)

    return true

  end

  def self.build_ips_bug(bugzilla_rest_session, new_entries_ips, new_entries_urls, problem, original_bug_id)
    summary = "New Web Content Categorization Complaint generated at #{DateTime.now.utc.strftime("%Y-%m-%d %H:%M")}"

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



end
