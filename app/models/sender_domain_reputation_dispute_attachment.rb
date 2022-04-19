class SenderDomainReputationDisputeAttachment < ApplicationRecord

  belongs_to :sender_domain_reputation_dispute

  def self.build_and_push_to_bugzilla(bugzilla_rest_session, payload, user, sender_domain_reputation_dispute, remote = true)
    if remote == true
      file_content = open(payload[:url]).read
    else
      file_content = payload[:file_content].read
    end

    bug_proxy = bugzilla_rest_session.build_bug(id: sender_domain_reputation_dispute.id)

    options = {
        data: Base64.encode64(file_content),
        file_name: payload[:file_name],
        content_type: payload[:content_type],
        summary: payload[:file_name],
        comment: "a file: #{payload[:file_name]} for SDR case: #{sender_domain_reputation_dispute.dispute_id}"
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

      new_local_attachment

    end

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

end
