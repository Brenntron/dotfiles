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
      file_content.split("\n").map { |domain| { domain: domain } } # that's placeholder for the file attribute that can be added in the future
    rescue Aws::S3::Errors::NoSuchKey
      msg = "File named #{filename} for #{BUCKET_NAME} bucket on #{REGION} region was not found"
      Rails.logger.error(msg)
      []
    end

    private

      def s3_client
        @client ||= Aws::S3::Client.new(region: REGION)
      end
  end
end
