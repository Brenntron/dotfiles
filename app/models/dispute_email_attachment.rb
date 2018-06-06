class DisputeEmailAttachment < ApplicationRecord
  belongs_to :dispute_email



  def self.build_and_push_to_bugzilla(bugzilla_session, payload, user, dispute_email, remote = true)
    if remote == true
      file_content = open(payload[:url])
    else
      file_content = payload[:file_content]
    end

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

  def push_to_aws(file)

    s3           = Aws::S3::Resource.new
    bucket       = s3.bucket("analyst-console")
    prefix       = "#{Rails.env}/dispute_email_attachments/#{dispute_email.id}/"
    s3_url       = []

    key    = prefix + "#{file.original_filename}"
    object = bucket.object(key)
    object.upload_file(File.open(file.tempfile))
    s3_url = {file.original_filename => [object.key, file] }


    DisputeEmailAttachment.create(dispute_email_id: dispute_email.id,
                                  file_file_name: s3_url.keys.first,
                                  file_content_type: s3_url.values.flatten[1].content_type,
                                  file_file_size: s3_url.values.flatten[1].size,
                                  path:      s3_url.values.flatten[0])

  end

  def s3_url
    Aws::S3::Presigner.new.presigned_url(:get_object, bucket: 'analyst-console', key: self.path).to_s
  end


end
