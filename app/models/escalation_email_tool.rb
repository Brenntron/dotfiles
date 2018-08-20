class EscalationEmailTool

  DEFAULT_EMAIL = "no-reply@#{DisputeEmail::EMAIL_DOMAIN}"

  def self.generate_email_info(params, current_user)

    email_params = {}

    if current_user.email.present?
      email_params[:to] = [params[:to], current_user.email]
    else
      email_params[:to] = params[:to]
    end
    if params[:from].present?
      email_params[:from] = params[:from]
    else
      email_params[:from] = DEFAULT_EMAIL
    end

    email_params[:subject] = params[:subject]
    email_params[:body] = params[:body]

    attachments_to_mail = []

    if params[:attachments].present?
      params[:attachments].each do |key, attachment|

        new_attachment = {}
        new_attachment[:file_name] = attachment.filename
        new_attachment[:file_url] = push_to_aws(attachment)
        attachments_to_mail << new_attachment
      end
    end


    conn = ::Bridge::SendEmailEvent.new(addressee: 'talos-intelligence')
    conn.post(email_params, attachments_to_mail)
  end


  def self.push_to_aws(file)

    unique_id = Time.now.to_i

    config_values = Rails.configuration.peakebridge.sources["snort-org"]
    Aws.config.update(
        {
            credentials: Aws::Credentials.new(config_values['aws_access_key_id'], config_values['aws_secret_access_key']),
            region: config_values['aws_region']
        }
    )

    s3           = Aws::S3::Resource.new(region: config_values['aws_region'])
    bucket       = s3.bucket("analyst-console")
    prefix       = "#{Rails.env}/#{unique_id}/#{file.filename}/"
    s3_url       = []

    key    = prefix + "#{file.filename}"
    object = bucket.object(key)
    object.upload_file(File.open(file.tempfile))
    s3_url = {file.filename => [object.key, file] }

    s3_url(s3_url.values.flatten[0])


  end


  def self.s3_url(s3_path)
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
