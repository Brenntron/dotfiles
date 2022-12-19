require 'parquet'

class Ngfw::DataFetcher
  class << self
    SOURCE_FILE_URL = 'http://feeds.ironport.com/ngfw/data/uncat_detail.txt'.freeze
    AWS_REGION = 'us-east-1'
    BUCKET = 'talos-mspl-int'
    PREFIX = 'mspl/udc/output/'
    PRODUCT_FAMILY = '/product_family=_SDS_EDGE'

    def fetch
      creds = Aws::Credentials.new(Rails.configuration.ngfw_telemetry.aws_access_key_id, Rails.configuration.ngfw_telemetry.aws_secret_access_key)
      client = Aws::S3::Client.new(region: AWS_REGION, credentials: creds)

      output = client.list_objects({bucket: BUCKET, prefix: PREFIX})
      timestamp_list = output.contents.map {|m| m.key.split(PREFIX).last.split('/').first.split('_').first}.uniq.sort.reverse

      file_key = nil
      timestamp_list.each do |timestamp|
        file_key = client.list_objects({bucket: BUCKET, prefix: "#{PREFIX}#{timestamp}#{PRODUCT_FAMILY}"})&.contents&.first&.key
        break if file_key.present?
      end

      raise "Unable to find data file" unless file_key
      tempfile = Tempfile.new(['data', '.snappy.parquet'])
      client.get_object({bucket: BUCKET, key: file_key, response_target: tempfile.path})
      tempfile.rewind

      table = Arrow::Table.load(tempfile.path)

      tempfile.close
      tempfile.unlink

      table
    end

    #deprecated
    def fetch_old
      data = []
      URI.parse(SOURCE_FILE_URL).open do |file|
        file.drop(1).each do |ngfw_row| # drop first line - it contains field names
          data.push(parse_row(ngfw_row))
        end
      end
      data
    end

    private

    def parse_row(ngfw_row)
      domain, count = ngfw_row.split(',')
      {
        domain: domain,
        traffic_hits: count.to_i
      }
    rescue StandardError
      Rails.logger.error "Failed to parse NGFW domain #{domain}"
    end
  end
end
