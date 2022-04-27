class SenderDomainReputationDisputeAttachment < ApplicationRecord

  belongs_to :sender_domain_reputation_dispute

  CORPUS_SPAM = "spam@access.ironport.com"
  CORPUS_HAM = "ham@access.ironport.com"
  CORPUS_ADS = "ads@access.ironport.com"
  CORPUS_NOT_ADS = "not_ads@access.ironport.com"
  CORPUS_PHISH = "phish@access.ironport.com"
  CORPUS_VIRUS = "virus@access.ironport.com"

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

  def send_to_corpus(corpus_submission_category, base_subject, file, tag, bugzilla_session)

    email_args = {}
    email_args[:to] = corpus_submission_category
    email_args[:from] = "noreply@talosintelligence.com"
    email_args[:subject] = tag + " " + base_subject
    email_args[:body] = ""

    #payload = {}
    #payload[:file_name] = attachment["filename"]
    #payload[:file_content] = attachment["tempfile"]
    #payload[:content_type] = attachment["type"]
    #new_local_attachment = DisputeEmailAttachment.build_and_push_to_bugzilla(bugzilla_rest_session, payload, current_user, new_email, false)

    attachment = {}
    attachment["filename"] = self.file_name
    attachment["data"] = file.file_contents

    s3_file_path = self.push_to_aws(attachment)
    new_attachment = {}
    new_attachment[:file_name] = attachment["filename"]
    new_attachment[:file_url] = self.s3_url(s3_file_path)




    conn = ::Bridge::SendEmailEvent.new(addressee: 'talos-intelligence')
    conn.post(email_args, [new_attachment])

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
    prefix       = "#{Rails.env}/ac_sdr_attachments/#{self.id}/"
    s3_url       = []

    key    = prefix + "#{file['filename']}"
    object = bucket.object(key)
    #object.upload_file(File.open(file['tempfile']))
    object.upload_stream do |write_stream|
      write_stream << file['data']
    end
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
