class Complaint < ApplicationRecord
  belongs_to :user
  belongs_to :customer
  has_many :complaint_entries

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


  def self.is_possible_company_duplicate(dispute, entry, entry_type)
    company_id = dispute.customer.company.id

    candidates = Complaint.includes(:customer).includes(:complaint_entries).where(:status != RESOLVED, :customers => {:company_id => company_id}, :complaint_entries => {:entry_type => entry_type})

    if candidates.blank?
      return false
    end

    candidates.each do |candidate|
      if entry_type == "IP"
        possible_duplicates = candidate.dispute_entries.any? {|entry| entry.ip_address == entry}
      end

      if entry_type == "URI"
        possible_duplicates = candidate.dispute_entries.any? {|entry| entry.hostname == entry}
      end

    end

    return possible_duplicates.present?

  end



  def self.process_bridge_payload(message_payload)
    user = User.where(cvs_username:"vrtincom").first
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

    bug_stub_hash = Bug.bugzilla_create(bug_factory, bug_attrs, user: user)


    new_complaint = Complaint.new
    new_complaint.submission_type = message_payload["payload"]["submission_type"]
    new_complaint.id = bug_stub_hash["id"]
    new_complaint.description = message_payload["payload"]["problem"]
    new_complaint.user_id = user.id
    new_complaint.ticket_source_key = message_payload["source_key"]
    new_complaint.ticket_source = "talos-intelligence"
    new_complaint.ticket_source_type = message_payload["source_type"]
    new_complaint.customer_id = Customer.process_and_get_customer(message_payload).id

    new_complaint.save

    #IP based and DOMAIN based entry creation is similar enough that it might be worth investigating refactoring into a common method
    #TODO: investigate above to see if its worth refactoring, and refactor it if so.

    new_entries_ips.each do |key, entry|

      new_payload_item = {}
      new_payload_item[:sugg_type] = entry["cat_sugg"]
      new_payload_item[:status] = "pending"
      new_payload_item[:resolution_message] = ""
      new_payload_item[:resolution] = ""
      new_payload_item[:company_dup] = is_possible_company_duplicate(new_complaint, key, "IP")
      return_payload[key] = new_payload_item

      new_complaint_entry = ComplaintEntry.new
      new_complaint_entry.complaint_id = new_complaint.id
      new_complaint_entry.ip_address = key
      #new_complaint_entry.wbrs_score = entry["wbrs_score"]
      #new_complaint_entry.sbrs_score = entry["sbrs_score"]
      new_complaint_entry.entry_type = "IP"
      new_complaint_entry.suggested_disposition = entry["cat_sugg"]
      new_complaint_entry.save


    end

    new_entries_urls.each do |entry|
      url_parts = parse_url(key)
      new_complaint_entry = ComplaintEntry.new
      new_complaint_entry.complaint_id = new_complaint.id
      new_complaint_entry.uri = key
      new_complaint_entry.entry_type = "URI/DOMAIN"
      #new_complaint_entry.score_type = "WBRS"
      #new_complaint_entry.score = entry["WBRS_SCORE"].to_f
      new_complaint_entry.suggested_disposition = entry["cat_sugg"]
      new_complaint_entry.subdomain = url_parts[:subdomain]
      new_complaint_entry.domain = url_parts[:domain]
      new_complaint_entry.path = url_parts[:path]
      new_complaint_entry.save

      new_payload_item = {}
      new_payload_item[:sugg_type] = entry["cat_sugg"]
      new_payload_item[:status] = "pending"
      new_payload_item[:resolution_message] = ""
      new_payload_item[:resolution] = ""
      new_payload_item[:company_dup] = is_possible_company_duplicate(new_complaint, new_complaint_entry.hostname, "URI/DOMAIN")
      return_payload[key] = new_payload_item

    end

    #change this
    return_message = {
        "envelope":
            {
                "channel": "ticket-acknowledge",
                "addressee": "talos-intelligence",
                "sender": "analyst-console"
            },
        "message": {"source_key":params["source_key"],"ac_status":"CREATE_ACK", "ticket_entries": return_payload, "case_email": nil}
    }
  end

end



