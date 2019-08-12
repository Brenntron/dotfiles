class Complaint < ApplicationRecord
  belongs_to :customer, optional: true
  has_many :complaint_entries, dependent: :restrict_with_exception
  has_and_belongs_to_many :complaint_tags, dependent: :destroy

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

  scope :active_count , -> {where(status:ACTIVE).count}
  scope :completed_count , -> {where(status:COMPLETED).count}
  scope :new_count , -> {where(status:NEW).count}
  scope :overdue_count , -> {where("created_at < ?",Time.now - 24.hours).where.not(status:COMPLETED).count}
  scope :open_comps, -> { where.not(status: COMPLETED) }
  scope :from_ti, -> { includes(:complaint_entries).where(channel: TI_CHANNEL) }
  scope :from_int, -> { includes(:complaint_entries).where(channel: INT_CHANNEL) }
  scope :from_wbnp, -> { includes(:complaint_entries).where(channel: WBNP_CHANNEL) }
  scope :by_guest, -> { joins(:customer).where(customers: {company_id: Company.guest.id}) }
  scope :by_cust, -> { joins(:customer).where.not(customers: {company_id: Company.guest.id}) }

  def set_status(new_status)
    status_list = complaint_entries.map{|entry| entry.status}
    case new_status
      when NEW
        update(status: status_list.any? {|item| [ASSIGNED,PENDING,COMPLETED].include? item}? ACTIVE: NEW)
      when ASSIGNED || PENDING
        update(status:ACTIVE)
      when COMPLETED
        update(status: status_list.any? {|item| [ASSIGNED,PENDING,NEW].include? item}? ACTIVE: COMPLETED)
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


  def self.commit_without_complaint(ip_or_uri:, categories_string:, description:, user:, bugzilla_rest_session:)
    # check to see if URL is in Top URLS
    top_url = Wbrs::TopUrl.check_urls([ip_or_uri]).first.is_important
    if top_url
      #create a complaint/complaint entry and set to pending
      Complaint.create_action(bugzilla_rest_session, ip_or_uri, description, nil, nil, PENDING, categories_string)
    else
      # Look for existing prefix
      existing_prefix = Wbrs::Prefix.where({urls: [ip_or_uri]})
      category_ids_array = Wbrs::Category.get_category_ids(categories_string.split(','))

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
    possibles = complaint.customer.complaints.where.not(status: [ RESOLVED, DUPLICATE ])
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
      return_payload[ip] = new_payload_item
      new_complaint_entry = ComplaintEntry.new
      new_complaint_entry.complaint_id = complaint.id
      new_complaint_entry.ip_address = ip
      new_complaint_entry.entry_type = "IP"
      new_complaint_entry.status = ComplaintEntry::RESOLVED
      new_complaint_entry.resolution = ComplaintEntry::STATUS_RESOLVED_DUPLICATE
      new_complaint_entry.case_resolved_at = resolved_at
      new_complaint_entry.save
    end
    new_entries_urls.each do |url, entry|
      new_payload_item = {}
      new_payload_item[:resolution_message] = "This is a duplicate of a currently active ticket."
      new_payload_item[:resolution] = "DUPLICATE"
      new_payload_item[:status] = TI_RESOLVED
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
    end

    conn = ::Bridge::DisputeCreatedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: source_key, ac_id: complaint.id)
    conn.post(return_payload, "")

  end




  def self.process_bridge_payload(message_payload)

    begin
      ActiveRecord::Base.transaction do
        max_wait_for_job = 60 #seconds

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


        new_complaint = Complaint.new
        new_complaint.submission_type = message_payload["payload"]["submission_type"]
        new_complaint.id = bug_proxy.id
        new_complaint.description = message_payload["payload"]["problem"]
        new_complaint.ticket_source_key = message_payload["source_key"]
        new_complaint.ticket_source = "talos-intelligence"
        new_complaint.ticket_source_type = message_payload["source_type"]
        customer = Customer.process_and_get_customer(message_payload)
        new_complaint.customer_id = customer&.id
        new_complaint.status = NEW
        new_complaint.channel = TI_CHANNEL
        new_complaint.submitter_type = (new_complaint.customer.nil? || new_complaint.customer&.company_id == guest.id) ? SUBMITTER_TYPE_NONCUSTOMER : SUBMITTER_TYPE_CUSTOMER

        new_complaint.save!

        response = is_possible_customer_duplicate?(new_complaint, new_entries_ips, new_entries_urls)

        if response[:is_dupe] == true
          manage_duplicate_complaint(new_complaint, response[:authority], new_entries_ips, new_entries_urls, message_payload["source_key"] )
          return
        end

        #IP based and DOMAIN based entry creation is similar enough that it might be worth investigating refactoring into a common method
        #TODO: investigate above to see if its worth refactoring, and refactor it if so.

        new_entries_ips.each do |key, entry|

          prefix_response = Wbrs::Prefix.where({:urls => [key]})
          new_payload_item = {}
          new_payload_item[:sugg_type] = entry['wbrs']["cat_sugg"] unless entry['wbrs']['cat_sugg'].blank?
          new_payload_item[:status] = TI_NEW
          new_payload_item[:resolution_message] = ""
          new_payload_item[:resolution] = ""
          new_payload_item[:company_dup] = is_possible_company_duplicate(new_complaint, key, "IP")
          return_payload[key] = new_payload_item

          new_complaint_entry = ComplaintEntry.new
          new_complaint_entry.complaint_id = new_complaint.id
          new_complaint_entry.user_id = user.id
          new_complaint_entry.ip_address = key
          new_complaint_entry.wbrs_score = entry[:wbrs]["WBRS_SCORE"]
          new_complaint_entry.entry_type = "IP"
          new_complaint_entry.suggested_disposition = entry['wbrs']["cat_sugg"].join(",") unless entry['wbrs']['cat_sugg'].blank?

          if prefix_response.first&.is_active == 1
            new_complaint_entry.url_primary_category = entry['wbrs']["current_cat"] unless entry['wbrs']['current_cat'].blank?
          else
            new_complaint_entry.url_primary_category = nil
          end

          new_complaint_entry.status = ComplaintEntry::NEW
          #lets query the top url API endpoint to determine if this is an important site or not
          # but you better believe i dont trust this API so we have some checks to ensure the entry gets created
          importance = Wbrs::TopUrl.check_urls([key]).first.is_important
          new_complaint_entry.is_important = importance if !!importance == importance #making sure importance is a boolean
          new_complaint_entry.save!

          ComplaintEntryPreload.generate_preload_from_complaint_entry(new_complaint_entry)


          begin
            #ces = ComplaintEntryScreenshot.create(complaint_entry_id: new_complaint_entry.id )
            # CALL SCREENSHOT BACKGROUND JOB! with ces.id and new_complaint_entry.hostlookup
            #ces.grab_screenshot
          rescue Exception => e
            #Rails.logger.error("#{e.message}")
            #ces = ComplaintEntryScreenshot.new
            #ces.error_message = e.message
            #ces.complaint_entry_id = new_complaint_entry.id
            #open("app/assets/images/failed_screenshot.jpg") do |f|
            #  ces.screenshot = f.read
            #end
            #ces.save!
          end
        end

        new_entries_urls.each do |key, entry|

          prefix_response = Wbrs::Prefix.where({:urls => [key]})
          url_parts = parse_url(key)
          new_complaint_entry = ComplaintEntry.new
          new_complaint_entry.complaint_id = new_complaint.id
          new_complaint_entry.user_id = user.id
          new_complaint_entry.uri = key.gsub(/\Ahttp[s]*\:\/\//, '').gsub(/\A[0-9]*www[0-9]*\./, '')
          new_complaint_entry.entry_type = "URI/DOMAIN"
          new_complaint_entry.wbrs_score = entry['WBRS_SCORE']
          new_complaint_entry.suggested_disposition = entry["cat_sugg"].join(",") unless entry['cat_sugg'].blank?


          if prefix_response.first&.is_active?
            new_complaint_entry.url_primary_category = entry["current_cat"] unless entry['current_cat'].blank?
          else
            new_complaint_entry.url_primary_category = nil
          end

          new_complaint_entry.subdomain = url_parts[:subdomain]
          new_complaint_entry.domain = url_parts[:domain]
          new_complaint_entry.path = url_parts[:path]
          new_complaint_entry.status = ComplaintEntry::NEW
          #lets query the top url API endpoint to determine if this is an important site or not
          # but you better believe i dont trust this API so we have some checks to ensure the entry gets created
          importance = Wbrs::TopUrl.check_urls([key]).first.is_important
          new_complaint_entry.is_important = !!importance #making sure importance is a boolean
          new_complaint_entry.save!

          new_payload_item = {}
          new_payload_item[:sugg_type] = entry["cat_sugg"].join(",") unless entry['cat_sugg'].blank?
          new_payload_item[:status] = TI_NEW
          new_payload_item[:resolution_message] = ""
          new_payload_item[:resolution] = ""
          new_payload_item[:company_dup] = is_possible_company_duplicate(new_complaint, key, "URI/DOMAIN")
          return_payload[key] = new_payload_item

          ComplaintEntryPreload.generate_preload_from_complaint_entry(new_complaint_entry)

          begin
            #ces = ComplaintEntryScreenshot.create(complaint_entry_id: new_complaint_entry.id )
            # CALL SCREENSHOT BACKGROUND JOB! with ces.id and new_complaint_entry.hostlookup
            #ces.grab_screenshot
          rescue Exception => e
            #ces = ComplaintEntryScreenshot.new
            #ces.error_message = e.message
            #ces.complaint_entry_id = new_complaint_entry.id
            #open("app/assets/images/failed_screenshot.jpg") do |f|
            #  ces.screenshot = f.read
            #end
            #ces.save!
          end
        end

        conn = ::Bridge::ComplaintCreatedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: message_payload["source_key"], ac_id: new_complaint.id)
        conn.post(return_payload)

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
      end
    rescue Exception => e
      Rails.logger.error "Complaint failed to save, backing out all DB changes."
      Rails.logger.error $!
      Rails.logger.error $!.backtrace.join("\n")

      conn = ::Bridge::ComplaintFailedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: message_payload["source_key"])
      conn.post
    end
  end

  def self.get_latest_wbnp_complaints

      new_report = WbnpReport.new

      all_complaints = Wbrs::RuleUiComplaint.where({:add_channels => [WBNP_CHANNEL], :statuses => ['new']})["data"]

      #all_complaints.each do |rule_ui_complaint|
      #  uri_to_test = compile_parts_to_uri(rule_ui_complaint)
      #  rule_ui_complaint_exists = ComplaintEntry.where("uri like ?", "%" + uri_to_test + "%")

      #  if rule_ui_complaint_exists.blank? && rule_ui_complaint['add_channel'] == WBNP_CHANNEL
      #    new_complaints << rule_ui_complaint
      #  end
      #end
      new_report.notes = ""
      new_report.cases_imported = 0
      new_report.cases_failed = 0
      new_report.total_new_cases = all_complaints.size
      new_report.status = WbnpReport::ACTIVE
      new_report.save

      start_wbnp_pull(new_report.id)

      new_report

  end

  class << self
    def start_wbnp_pull(new_report_id)
      new_report = WbnpReport.find(new_report_id)
      begin
        all_complaints = Wbrs::RuleUiComplaint.where({:add_channels => [WBNP_CHANNEL], :statuses => ['new']})["data"]
        bugzilla_rest_session = BugzillaRest::Session.default_session
        all_complaints.each do |new_ui_complaint|
          if new_ui_complaint['add_channel'] == WBNP_CHANNEL
            begin
              rule_ui_wbnp_create_action(new_ui_complaint, new_report, bugzilla_rest_session: bugzilla_rest_session)
            rescue => e
              new_report.cases_failed += 1
              new_report.notes += "SWP \n uri: #{new_ui_complaint.inspect} | failure: #{e.message} #{e.backtrace.join("\n")}\n"
              new_report.save
            end
          end
        end

        new_report.status = WbnpReport::COMPLETE
        new_report.save
      rescue => e
        new_report.status = WbnpReport::ERROR
        new_report.notes += "\n\n----------\nPull suddenly ended with error: #{e.message} #{e.backtrace.join("\n")}\n\n"
        new_report.save
      end

    end
    handle_asynchronously :start_wbnp_pull

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

  def self.rule_ui_wbnp_create_action(rule_ui_complaint, wbnp_report, bugzilla_rest_session:)
    #"#{{"add_channel"=>"wbnp", "comment"=>"", "complaint_id"=>105, "complaint_type"=>"unknown", "customer_name"=>"ORANGE BUSINES SERVICES", "description"=>"",
    # "domain"=>"fmp-usmba.ac.ma", "path"=>"/cdim/mediatheque/e_theses/257-16.pdf", "port"=>0, "protocol"=>"http", "region"=>"", "resolution"=>nil, "state"=>"new",
    # "subdomain"=>"scolarite", "tag"=>nil, "url_query_string"=>"", "when_added"=>"Thu, 30 Aug 2018 15:00:05 GMT", "when_last_updated"=>"Thu, 30 Aug 2018 15:00:05 GMT",
    # "who_updated"=>""}}"


    uri = compile_parts_to_uri(rule_ui_complaint)
    description = "WBNP Sourced Complaint"

    user = User.where(cvs_username:"vrtincom").first

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

    begin
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
      ComplaintEntry.create_wbnp_complaint_entry(new_complaint, uri, rule_ui_complaint, User.where(display_name:"Vrt Incoming").first, ComplaintEntry::NEW, primary_category)
      Wbrs::RuleUiComplaint.assign_tickets({:complaint_ids => [rule_ui_complaint["complaint_id"]], :user => "admatter"})
      wbnp_report.cases_imported += 1

    rescue Exception => e
      wbnp_report.cases_failed += 1
      wbnp_report.notes += "\n\nRUWCA\n uri: #{uri} | failure: #{e.message} \n #{e.backtrace.join("\n")}"
    end

    wbnp_report.save
  end

  def self.create_action(bugzilla_rest_session, ips_urls, description, customer, tags, status=NEW, categories = nil)

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
    new_complaint = Complaint.create(id: bug_proxy.id,
                                     description: description,
                                     customer_id: cust&.id,
                                     status: status,
                                     channel: INT_CHANNEL)


    handle_tags(new_complaint, tags) if tags

    ips_urls.split(' ').each do |ip_url|
      ComplaintEntry.create_complaint_entry(new_complaint, ip_url, User.where(display_name:"Vrt Incoming").first, status, categories)
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
end



