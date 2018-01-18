class S3Url < FileReference
  # If location input is an URL, capture path from URL.
  # @param [String] location input which might be a full URL.
  # @return [String] Corrected location value.
  def self.sanitize_location(location)
    if /\A\w+:\/\/[-\.\w]+\/(?<encoded>[^\?]*)(\?.*)?\z/ =~ location
      URI.unescape(encoded)
    else
      location
    end
  end

  # @return [Hash] config section for this object's source.
  def config_values
    @config_values ||= Rails.configuration.peakebridge.sources[self.source]
  end

  # @return [Aws::S3::Bucket] the S3 bucket object needed.
  def bucket
    unless @bucket
      credentials = Aws::Credentials.new(config_values['aws_access_key_id'], config_values['aws_secret_access_key'])
      resource = Aws::S3::Resource.new(region: config_values['aws_region'], credentials: credentials)
      @bucket = resource.bucket(config_values['aws_bucket'])
    end
    @bucket
  end

  # @return [IO] File object from S3 which can be read.
  def get_file
    bucket.object(self.location).get.body
  end

  # Downloads S3 file contents into local file
  # @return [LocalFile] object referring to local file which has been downloaded
  def download
    relative_path = "#{self.source}/#{local.id}-#{self.file_name}"
    LocalFile.copy_local(get_file, relative_path, attributes.slice(*%w{file_name file_type_name source}))
  end
end
