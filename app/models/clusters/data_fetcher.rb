class Clusters::DataFetcher
  class << self
    def fetch(date=nil)
      files_list = bucket_objects
      file = s3_client.get_object(bucket: config[:bucket], key: files_list.contents.first.key)
      csv_data = []
      begin
        CSV.parse(file.body.read, headers: true) do |row| csv_data << row.to_hash end
      rescue CSV::MalformedCSVError => e
        msg = "error parsing csv file: #{file} in bucket #{config[:bucket]}"
        Rails.logger.error(msg)
        []
      end
      csv_data
    rescue Aws::S3::Errors::NoSuchKey => e
      msg = "File in #{config[:bucket]} bucket was not found"
      Rails.logger.error(msg)
      []
    end

    private

    def s3_client
      credentials = Aws::Credentials.new(
        config[:access_key_id],
        config[:access_key_secret]
      )
      Aws::S3::Client.new(region: config[:region], credentials: credentials)
    end

    def bucket_objects
      s3_client.list_objects(bucket: config[:bucket], prefix: config[:prefix])
    end

    def config
      aws_config = Rails.configuration.clusters_telemetry_source
      {
        access_key_id: aws_config.aws_access_key_id,
        access_key_secret: aws_config.aws_secret_access_key,
        prefix: aws_config.aws_prefix,
        bucket: aws_config.aws_bucket,
        region: aws_config.aws_region
      }
    end
  end
end