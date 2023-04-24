require 'open-uri'
class SenderDomainReputationDisputeAttachment < ApplicationRecord

  belongs_to :sender_domain_reputation_dispute

  CORPUS_SPAM = "spam@access.ironport.com"
  CORPUS_HAM = "ham@access.ironport.com"
  CORPUS_ADS = "ads@access.ironport.com"
  CORPUS_NOT_ADS = "not_ads@access.ironport.com"
  CORPUS_PHISH = "phish@access.ironport.com"
  CORPUS_VIRUS = "virus@access.ironport.com"

  CORPUS_EMAIL_LIST= [CORPUS_SPAM, CORPUS_HAM, CORPUS_ADS, CORPUS_NOT_ADS, CORPUS_PHISH, CORPUS_VIRUS]
  ALL_POSSIBLE_TAGS = ["[SUSPECTED SPAM]", "[MARKETING]", "[SOCIAL NETWORK]", "[BULK]", "[WARNING: VIRUS DETECTED]"]
  FILE_EXTENTIONS_TO_PROCESS = ['.eml', '.msg'].freeze

  MODEL_PATH = "/sender_domain_reputation_dispute_attachments/"

  FULL_FILE_DIRECTORY_PATH = Rails.configuration.base_host_path + Rails.configuration.base_file_path + MODEL_PATH

  def self.build_and_push_to_bugzilla(payload, sender_domain_reputation_dispute, remote = true)
    new_local_attachment = nil
    if payload[:url].blank? && payload["url"].present?
      payload[:url] = payload["url"]
    end
    if remote == true
      file_content = open(payload[:url]).read
    else
      file_content = payload[:file_content].read
    end

    #bug_proxy = bugzilla_rest_session.build_bug(id: sender_domain_reputation_dispute.id)

    #options = {
    #    data: Base64.encode64(file_content),
    #    file_name: payload[:file_name],
    #    content_type: payload[:content_type],
    #    summary: payload[:file_name],
    #    comment: "a file: #{payload[:file_name]} for SDR case: #{sender_domain_reputation_dispute.id}"
    #}

    #attachment_proxy = bug_proxy.create_attachment!(options)
    #new_attachment_id = attachment_proxy.id


    new_local_attachment = new(
        sender_domain_reputation_dispute_id: sender_domain_reputation_dispute.id,
        size: file_content.length,
        file_name: payload[:file_name])
        #direct_upload_url: "https://" + Rails.configuration.bugzilla_host + "/attachment.cgi?id=" + new_attachment_id.to_s)
        #direct_upload_url: "#{FULL_FILE_PATH}")
    new_local_attachment.save!

    full_file_path = FULL_FILE_DIRECTORY_PATH + "#{new_local_attachment.id.to_s}/#{new_local_attachment.file_name}"

    directory_to_create = Pathname(full_file_path)
    directory_to_create.dirname.mkpath

    File.open(full_file_path, "w") { |f| f.write file_content }

    new_local_attachment.direct_upload_url = full_file_path
    new_local_attachment.save

    new_local_attachment
  end

  def parse_email_content
    file_data = File.open(self.direct_upload_url).read

    if file_data.present? && FILE_EXTENTIONS_TO_PROCESS.include?(File.extname(self.file_name))

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
  #tags can be: [SUSPECTED SPAM], [MARKETING], [SOCIAL NETWORK], [BULK], [WARNING: VIRUS DETECTED]
  # BugzillaRest::Session.default_session
  def send_to_corpus(corpus_submission_category, base_subject, tag, bugzilla_session=nil)
    #bug_proxy = bugzilla_session.build_bug(id: self.sender_domain_reputation_dispute.id)
    #bug_attachments = bug_proxy.attachments
    file = File.open(self.direct_upload_url)
    #bug_attachments.each do |bug_attachment|
    #  if bug_attachment.id == self.id
    #    file = bug_attachment
    #  end
    #end


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
    attachment["data"] = file.read

    s3_file_path = self.push_to_aws(attachment)
    new_attachment = {}
    new_attachment[:file_name] = attachment["filename"]
    new_attachment[:file_url] = self.s3_url(s3_file_path)

    puts "\n---------------------------------------------------\n"
    puts new_attachment.inspect.to_s

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
    beaker_data[:response] = {}
    beaker_data[:response][:data] = {}
    domain_of_parent = self.sender_domain_reputation_dispute.domain_name

    begin
      self.reload
      headers = JSON.parse(self.email_header_data)
      possible_from = []
      headers.keys.each do |key|
        if key.downcase.include?("from")
          possible_from += SenderDomainReputationDisputeAttachment.extract_emails_to_array(headers[key])
        end
      end

      possible_from = possible_from.uniq

      mail_data_params = {}
      mail_data_params[:dkim_disp] = [{}]
      mail_data_params[:dmarc_disp] = {}
      mail_data_params[:email_list] = {}

      possible_from.each do |from_email|
        mail_data_params[:from_hdr] = [{"addr" => from_email}]
        begin
          data_response = Beaker::Sdr.data_query('127.0.0.1', :mail_data_params => mail_data_params).to_h
        rescue
          data_response = ::Beaker::Sdr.data_query('127.0.0.1', :mail_data_params => mail_data_params).to_h
        end

        if data_response.present?
          data_response.keys.each do |key|
            begin
              data_response[key].to_json
            rescue
              data_response[key] = "could not translate encoded characters"
            end
          end
          begin
            data_response[:service_data].first[:data] = JSON.parse(data_response[:service_data].first[:data])
          rescue

          end
          beaker_data[:response][:data][from_email] = data_response
        end

      end
      beaker_data = beaker_data.to_json

    rescue => e
      Rails.logger.error e
      Rails.logger.error e.backtrace.join("\n")
      beaker_data = {:status => "failed", :message => "something went wrong trying to communicate with beaker and parsing data"}.to_json
    end
    self.beaker_info = beaker_data
    #puts "---------------------------------------------\nhere\n--------------------------------\n"
    #puts beaker_data
    self.save
  end

  def suggested_subject
    subject = ""

    if self.email_header_data.present?
      begin
        raw_data = JSON.parse(self.email_header_data)
        raw_data.keys.each do |key|
          if key.downcase.include?("subject")
            subject = raw_data[key].strip
          end
        end
      rescue
        subject = ""
      end
    end

    return subject
  end

  def self.extract_emails_to_array(txt)
    reg = /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i
    txt.scan(reg).uniq
  end
end
