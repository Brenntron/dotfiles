class Complaint < ApplicationRecord
  belongs_to :customer
  has_many :complaint_entries
  has_and_belongs_to_many :complaint_tags, dependent: :destroy

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

  TI_NEW = 'IN PROGRESS'
  TI_RESOLVED = 'RESOLVED'

  AC_SUCCESS = 'CREATE_ACK'
  AC_FAILED = 'CREATE_FAILED'
  AC_PENDING = 'CREATE_PENDING'

  SUBMITTER_TYPE_CUSTOMER = "CUSTOMER"
  SUBMITTER_TYPE_NONCUSTOMER = "NON-CUSTOMER"

  TI_CHANNEL = 'talosintel'
  INT_CHANNEL = 'internal'

  scope :active_count , -> {where(status:ACTIVE).count}
  scope :completed_count , -> {where(status:COMPLETED).count}
  scope :new_count , -> {where(status:NEW).count}
  scope :overdue_count , -> {where("created_at < ?",Time.now - 24.hours).where.not(status:COMPLETED).count}
  scope :from_ti, -> { includes(:complaint_entries).where(channel: TI_CHANNEL) }
  scope :from_int, -> { includes(:complaint_entries).where(channel: INT_CHANNEL) }

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



  def self.process_bridge_payload(message_payload)

    begin
      ActiveRecord::Base.transaction do

        user = User.where(cvs_username:"vrtincom").first
        guest = Company.where(:name => "Guest").first
        #TODO: this should be put in a params method
        message_payload["payload"] = message_payload["payload"].permit!.to_h
        new_entries_ips = message_payload["payload"]["investigate_ips"].permit!.to_h
        new_entries_urls = message_payload["payload"]["investigate_urls"].permit!.to_h

        return_payload = {}

        #create an escalations IP/DOMAIN bugzilla bug here and transfer id to new dispute

        bug_factory = Bugzilla::Bug.new(message_payload[:bugzilla_session])

        summary = "New Web Category Complaint generated at #{DateTime.now.utc.strftime("%Y-%m-%d %H:%M")}"

        full_description = %Q{
          IPs: #{new_entries_ips.map {|key, data| key.to_s}.join(', ')}
          URIs: #{new_entries_urls.map {|key, data| key.to_s}.join(', ')}
          Problem Summary: #{message_payload["payload"]["problem"]}
        }

        bug_attrs = {
            'product' => 'Escalations',
            'component' => 'WebCat',
            'summary' => summary,
            'version' => 'unspecified', #self.version,
            'description' => full_description,
            'priority' => 'Unspecified',
            'classification' => 'unclassified',
        }

        bug_stub_hash = Bug.bugzilla_create(bug_factory, bug_attrs, user, true)


        new_complaint = Complaint.new
        new_complaint.submission_type = message_payload["payload"]["submission_type"]
        new_complaint.id = bug_stub_hash["id"]
        new_complaint.description = message_payload["payload"]["problem"]
        new_complaint.ticket_source_key = message_payload["source_key"]
        new_complaint.ticket_source = "talos-intelligence"
        new_complaint.ticket_source_type = message_payload["source_type"]
        new_complaint.customer_id = Customer.process_and_get_customer(message_payload).id
        new_complaint.status = NEW
        new_complaint.channel = TI_CHANNEL

        new_complaint.submitter_type = new_complaint.customer.company_id == guest.id ? SUBMITTER_TYPE_NONCUSTOMER : SUBMITTER_TYPE_CUSTOMER

        new_complaint.save

        #IP based and DOMAIN based entry creation is similar enough that it might be worth investigating refactoring into a common method
        #TODO: investigate above to see if its worth refactoring, and refactor it if so.

        new_entries_ips.each do |key, entry|

          new_payload_item = {}
          new_payload_item[:sugg_type] = entry['wbrs']["cat_sugg"]
          new_payload_item[:status] = TI_NEW
          new_payload_item[:resolution_message] = ""
          new_payload_item[:resolution] = ""
          new_payload_item[:company_dup] = is_possible_company_duplicate(new_complaint, key, "IP")
          return_payload[key] = new_payload_item

          new_complaint_entry = ComplaintEntry.new
          new_complaint_entry.complaint_id = new_complaint.id
          new_complaint_entry.user_id = user.id
          new_complaint_entry.ip_address = key
          new_complaint_entry.wbrs_score = entry['wbrs']["wbrs_score"]
          new_complaint_entry.entry_type = "IP"
          new_complaint_entry.suggested_disposition = entry['wbrs']["cat_sugg"].join(",")
          new_complaint_entry.url_primary_category = entry['wbrs']["current_cat"]
          new_complaint_entry.status = ComplaintEntry::NEW
          new_complaint_entry.save


        end

        new_entries_urls.each do |key, entry|
          url_parts = parse_url(key)
          new_complaint_entry = ComplaintEntry.new
          new_complaint_entry.complaint_id = new_complaint.id
          new_complaint_entry.user_id = user.id
          new_complaint_entry.uri = key
          new_complaint_entry.entry_type = "URI/DOMAIN"
          new_complaint_entry.suggested_disposition = entry["cat_sugg"].join(",")
          new_complaint_entry.url_primary_category = entry["current_cat"]
          new_complaint_entry.subdomain = url_parts[:subdomain]
          new_complaint_entry.domain = url_parts[:domain]
          new_complaint_entry.path = url_parts[:path]
          new_complaint_entry.status = ComplaintEntry::NEW
          new_complaint_entry.save

          new_payload_item = {}
          new_payload_item[:sugg_type] = entry['wbrs']["cat_sugg"]
          new_payload_item[:status] = TI_NEW
          new_payload_item[:resolution_message] = ""
          new_payload_item[:resolution] = ""
          new_payload_item[:company_dup] = is_possible_company_duplicate(new_complaint, key, "URI/DOMAIN")
          return_payload[key] = new_payload_item

        end

        conn = ::Bridge::ComplaintCreatedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: message_payload["source_key"])
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
      logger.debug("Failed.")
      Rails.logger.error "Complaint failed to save, backing out all DB changes."
      Rails.logger.error $!
      Rails.logger.error $!.backtrace.join("\n")

      conn = ::Bridge::ComplaintFailedEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: message_payload["source_key"])
      conn.post
    end
  end

  def self.create_action(bugzilla_session, ips_urls, description, customer, tags)
    user = User.where(cvs_username:"vrtincom").first
    bug_factory = Bugzilla::Bug.new(bugzilla_session)

    summary = "New Web Category Complaint generated at #{DateTime.now.utc.strftime("%Y-%m-%d %H:%M")}"

    full_description = %Q{
          IPs/URIs: #{ips_urls}
          Problem Summary: #{description}
    }

    bug_attrs = {
        'product' => 'Escalations',
        'component' => 'WebCat',
        'summary' => summary,
        'version' => 'unspecified', #self.version,
        'description' => full_description,
        'priority' => 'Unspecified',
        'classification' => 'unclassified',
    }

    bug_stub_hash = Bug.bugzilla_create(bug_factory, bug_attrs, user, true)

    cust = find_customer(customer)
    new_complaint = Complaint.create(id: bug_stub_hash["id"],
                                     description: description,
                                     customer_id: cust.id,
                                     status: 'NEW',
                                     channel: INT_CHANNEL)

    handle_tags(new_complaint, tags) if tags

    ips_urls.split(' ').each do |ip_url|
      ComplaintEntry.create_complaint_entry(new_complaint, ip_url)
    end
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
end



