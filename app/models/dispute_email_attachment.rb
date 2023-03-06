class DisputeEmailAttachment < ApplicationRecord
  belongs_to :dispute_email

  MODEL_PATH = "dispute_email_attachments/"

  FULL_FILE_DIRECTORY_PATH = Rails.configuration.base_host_path + Rails.configuration.base_file_path + MODEL_PATH

  def self.build_and_push_to_bugzilla(bugzilla_rest_session, payload, user, dispute_email, remote = true)
    if remote == true
      file_content = open(payload[:url]).read
    else
      file_content = payload[:file_content].read
    end

    #bug_proxy = bugzilla_rest_session.build_bug(id: dispute_email.dispute.id)

    #options = {
    #  data: Base64.encode64(file_content),
    #  file_name: payload[:file_name],
    #  content_type: payload[:content_type],
    #  summary: payload[:file_name],
    #  comment: "a file: #{payload[:file_name]} for case: #{dispute_email.dispute_id} generated during a correspondence."
    #}

    #attachment_proxy = bug_proxy.create_attachment!(options)
    #new_attachment_id = attachment_proxy.id


    new_local_attachment = new(
        dispute_email_id: dispute_email.id,
        size: file_content.length,
        file_name: payload[:file_name]
    #direct_upload_url: "https://" + Rails.configuration.bugzilla_host + "/attachment.cgi?id=" + new_attachment_id.to_s
    )

    new_local_attachment.save!

    full_file_path = FULL_FILE_DIRECTORY_PATH + "#{new_local_attachment.id.to_s}/#{new_local_attachment.file_name}"

    directory_to_create = Pathname(full_file_path)
    directory_to_create.dirname.mkpath

    File.open(full_file_path, "w") { |f| f.write file_content }

    new_local_attachment.direct_upload_url = full_file_path
    new_local_attachment.save

    new_local_attachment

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

    key    = prefix + "#{file['filename']}"
    object = bucket.object(key)
    object.upload_file(File.open(file['tempfile']))

    s3_url = {file['filename'] => [object.key, file] }

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
