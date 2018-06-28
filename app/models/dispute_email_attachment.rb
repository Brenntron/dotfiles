class DisputeEmailAttachment < ApplicationRecord
  belongs_to :dispute_email



  def self.build_and_push_to_bugzilla(bugzilla_session, payload, user, dispute_email, remote = true)
    if remote == true
      file_content = open(payload[:url]).read
    else
      file_content = payload[:file_content].read
    end

    bug_stub = Bugzilla::Bug.new(bugzilla_session)

    options = {
      ids: dispute_email.dispute.id,
      data: XMLRPC::Base64.new(file_content),
      file_name: payload[:file_name],
      content_type: payload[:file_type],
      summary: payload[:file_name],
      comment: "a file: #{payload[:filename]} for case: #{dispute_email.dispute_id} generated during a correspondence."
    }

    attachment_hash = bug_stub.add_attachment(options)

    new_attachment_id = attachment_hash["ids"][0]

    if new_attachment_id.present?

      new_local_attachment = new(
          id: new_attachment_id,
          dispute_email_id: dispute_email.id,
          size: file_content.length,
          bugzilla_attachment_id: new_attachment_id,
          file_name: payload[:file_name],
          direct_upload_url: "https://" + Rails.configuration.bugzilla_host + "/attachment.cgi?id=" + new_attachment_id.to_s
      )

      new_local_attachment.save!

    end

  end

  def push_to_aws(file)

    config_values = Rails.configuration.peakebridge.sources["snort-org"]
    Aws.config.update(
        {
            credentials: Aws::Credentials.new(config_values['aws_access_key_id'], config_values['aws_secret_access_key']),
            region: config_values['aws_region']
        }
    )

    s3           = Aws::S3::Resource.new(region: config_values['aws_region'])
    bucket       = s3.bucket("analyst-console")
    prefix       = "#{Rails.env}/dispute_email_attachments/#{dispute_email.id}/"
    s3_url       = []

    key    = prefix + "#{file.filename}"
    object = bucket.object(key)
    object.upload_file(File.open(file.tempfile))
    s3_url = {file.filename => [object.key, file] }

    s3_url.values.flatten[0]


  end

  def s3_url(s3_path)
    config_values = Rails.configuration.peakebridge.sources["snort-org"]
    Aws.config.update(
        {
            credentials: Aws::Credentials.new(config_values['aws_access_key_id'], config_values['aws_secret_access_key']),
            region: config_values['aws_region']
        }
    )
    url = Aws::S3::Presigner.new.presigned_url(:get_object, bucket: 'analyst-console', key: s3_path, expires_in: 86400).to_s

    url
  end


end