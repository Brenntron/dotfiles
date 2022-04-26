class SenderDomainReputationDisputeAttachment < ApplicationRecord

  belongs_to :sender_domain_reputation_dispute

  def self.build_and_push_to_bugzilla(bugzilla_rest_session, payload, user, sender_domain_reputation_dispute, remote = true)

    new_local_attachment = nil
    if remote == true
      file_content = open(payload["url"]).read
    else
      file_content = payload[:file_content].read
    end

    bug_proxy = bugzilla_rest_session.build_bug(id: sender_domain_reputation_dispute.id)

    options = {
        data: Base64.encode64(file_content),
        file_name: payload[:file_name],
        content_type: payload[:content_type],
        summary: payload[:file_name],
        comment: "a file: #{payload[:file_name]} for SDR case: #{sender_domain_reputation_dispute.id}"
    }

    attachment_proxy = bug_proxy.create_attachment!(options)
    new_attachment_id = attachment_proxy.id

    if new_attachment_id.present?

      new_local_attachment = new(
          id: new_attachment_id,
          sender_domain_reputation_dispute_id: sender_domain_reputation_dispute.id,
          size: file_content.length,
          bugzilla_attachment_id: new_attachment_id,
          file_name: payload[:file_name],
          direct_upload_url: "https://" + Rails.configuration.bugzilla_host + "/attachment.cgi?id=" + new_attachment_id.to_s
      )

      new_local_attachment.save!



    end

    new_local_attachment
  end

  def parse_email_content(bug_attachment)

    file_data = bug_attachment.file_contents

    if file_data.present?

      header_json = SenderDomainReputationDisputeAttachment.parse_headers_to_array(file_data)

      self.email_header_data = header_json
      self.save!

    end

  end

  def self.parse_headers_to_array(file_data, convert_to_json = true)

    json_data = {}
    begin
      email_headers = Mail.new(file_data).header_fields
      email_headers.each do |header|
        json_data[header.name] = header.value
      end

    rescue
      json_data = {:status => "error"}
    end

    if convert_to_json == true
      json_data.to_json
    else
      json_data
    end

  end

  def self.get_mx_records(domain)
    mxs = Resolv::DNS.open do |dns|
      ress = dns.getresources(domain, Resolv::DNS::Resource::IN::MX)
      ress.map { |r| [r.exchange.to_s, IPSocket::getaddress(r.exchange.to_s)] }
    end
    return mxs
  end

  def retrieve_beaker_data_and_save

    beaker_data = {}
    beaker_data[:request] = {}
    beaker_data[:request][:mx_data] = []
    beaker_data[:response] = {}
    beaker_data[:response][:envelope] = []
    beaker_data[:response][:data] = []
    domain_of_parent = self.sender_domain_reputation_dispute.domain_name

    begin
      mx_records = SenderDomainReputationDisputeAttachment.get_mx_records(domain_of_parent)

      if mx_records.present?
        mx_records.each do |mx_record|
          beaker_data[:request][:mx_data] << {:exchange => mx_record.first, :ip_address => mx_record.last}

          envelope_response = Beaker::Sdr.envelope_query(mx_record.last).to_h
          envelope_response.keys.each do |key|
            begin
              envelope_response[key].to_json
            rescue
              envelope_response[key] = "could not translate encoded characters"
            end
          end
          data_response = Beaker::Sdr.data_query(mx_record.last).to_h
          data_response.keys.each do |key|
            begin
              data_response[key].to_json
            rescue
              data_response[key] = "could not translate encoded characters"
            end
          end
          beaker_data[:response][:envelope] << {:ip => mx_record.last, :response => envelope_response}
          beaker_data[:response][:data] = {:ip => mx_record.last, :response => data_response}

        end

      end
      beaker_data = beaker_data.to_json

    rescue => e
      Rails.logger.error e
      Rails.logger.error e.backtrace.join("\n")
      beaker_data = {:status => "failed", :message => "something went wrong trying to communicate with beaker and parsing data"}.to_json
    end
    self.beaker_info = beaker_data
    puts "---------------------------------------------\nhere\n--------------------------------\n"
    puts beaker_data
    self.save
  end


end
