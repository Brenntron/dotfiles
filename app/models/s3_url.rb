class S3Url < FileReference
  # If location input is an URL, capture path from URL.
  # @param [String] location input which might be a full URL.
  # @return [String] Corrected location value.
  def self.sanitize_location(location)
    # Regexp to parse path out of an http(s) URL.
    # If S3 location is an http/https URL, we just want the path, so fix it.
    # URL is in format of protocol+colon+slash+slash+host+slash+path+question-mark+query-string
    # Begining of string = \A (like ^, but ^ is for beginning of line which can occur within a string)
    # Protocol = \w+
    # Host = [-\.\w]+
    # Query String (optional) = \?.*
    # End of string = \z (like $, but $ is for end of line which can occur within a string)
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

end
