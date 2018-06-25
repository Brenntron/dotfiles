class Complaint < ApplicationRecord
  belongs_to :user
  belongs_to :customer
  has_many :complaint_entries

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

  def self.process_bridge_payload(message_payload)
    user = User.where(cvs_username:"vrtincom").first
    #TODO: this should be put in a params method
    message_payload["payload"] = message_payload["payload"].permit!.to_h
    new_entries_ips = message_payload["payload"]["investigate_ips"].permit!.to_h
    new_entries_urls = message_payload["payload"]["investigate_urls"].permit!.to_h

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

    new_entries_ips.each do |key, entry|
      url_parts = parse_url(key)
      new_complaint_entry = ComplaintEntry.new
      new_complaint_entry.subdomain = url_parts[:subdomain]
      new_complaint_entry.domain = url_parts[:domain]
      new_complaint_entry.path = url_parts[:path]
      new_complaint_entry.complaint_id = new_complaint.id
      new_complaint_entry.ip_address = key
      new_complaint_entry.wbrs_score = entry["wbrs_score"]
      new_complaint_entry.sbrs_score = entry["sbrs_score"]
      new_complaint_entry.suggested_disposition = entry["cat_sugg"]
      new_complaint_entry.save


    end

    new_entries_urls.each do |entry|

      new_complaint_entry = ComplaintEntry.new
      new_complaint_entry.complaint_id = new_complaint.id
      new_complaint_entry.ip_address = key
      new_complaint_entry.entry_type = "DOMAIN"
      new_complaint_entry.score_type = "WBRS"
      new_complaint_entry.score = entry["WBRS_SCORE"].to_f
      new_complaint_entry.suggested_disposition = entry["reg_sugg"]
      new_complaint_entry.save

    end

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


end



