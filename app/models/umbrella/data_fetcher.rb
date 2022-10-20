class Umbrella::DataFetcher
  class << self
    REGION = 'us-east-1'.freeze
    BUCKET_NAME = 'honeywell-uploads'.freeze
    FILENAME_SUFFIX = '.honeywell.nocats.txt'.freeze

    # Filename includes the day the file was uploaded
    # That's why we need date as a param
    def fetch(date = nil)
      date ||= DateTime.now
      date = date.strftime('%Y-%m-%d')
      filename = date + FILENAME_SUFFIX
      file_content = s3_client.get_object(bucket: BUCKET_NAME, key: filename).body.read
      file_content.split("\n").filter_map { |domain| { domain: domain } unless first_line_of_empty_file?(domain) }
    rescue Aws::S3::Errors::NoSuchKey
      msg = "File named #{filename} for #{BUCKET_NAME} bucket on #{REGION} region was not found"
      Rails.logger.error(msg)
      []
    end

    private

      # we should ignore default string of empty file: <?xml version=1.0 encoding=UTF-8?>
    def first_line_of_empty_file?(domain)
      %w[< xml version encoding > ?].all? { |x| domain.include? x }
    end

    def s3_client
      credentials = Aws::Credentials.new(Rails.configuration.umbrella_data_fetcher.aws_access_key_id,
                                         Rails.configuration.umbrella_data_fetcher.aws_secret_access_key)
      @client ||= Aws::S3::Client.new(region: REGION, credentials: credentials)
    end
  end
end
