class DisputeEmailAttachment < ApplicationRecord
  belongs_to :dispute_email



  def self.build_and_push_to_bugzilla(bugzilla_session, payload, user, dispute_email)
    file_content = open(payload[:url])

    bug_stub = Bugzilla::Bug.new(bugzilla_session)

    options = {
      ids: dispute_email.dispute.id,
      data: XMLRPC::Base64.new(file_content),
      file_name: payload[:file_name]
    }

    attachment_hash = bug_stub.add_attachment(options)

    new_attachment_id = attachment_hash["ids"][0]

    if new_attachment_id.present?
      begin
        create(
            id: new_attachment_id,
            dispute_email_id: dispute_email.id,
            size: file_content.length,
            bugzilla_attachment_id: new_attachment_id,
            file_name: payload[:file_name],
            direct_upload_url: "https://" + Rails.configuration.bugzilla_host + "/attachment.cgi?id=" + new_attachment_id.to_s
        )
      rescue Exception => e

      end
    end

  end


end
