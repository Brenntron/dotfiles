class S3Url < FileReference
  def url
    location
  end

  def config_values
    @config_values ||= Rails.configuration.peakebridge.sources[self.source]
  end

  def bucket
    unless @bucket
      credentials = Aws::Credentials.new(config_values['aws_access_key_id'], config_values['aws_secret_access_key'])
      resource = Aws::S3::Resource.new(region: config_values['aws_region'], credentials: credentials)
      @bucket = resource.bucket(config_values['aws_bucket'])
    end
    @bucket
  end

  def get_file
    bucket.object(self.location).get.body
  end

  def download
    local = LocalFile.create(attributes.slice(*%w{file_name file_type_name source}))
    relative_path = "#{self.source}/#{local.id}-#{self.file_name}"
    local.copy_local(get_file, relative_path)
    local
  end
end
