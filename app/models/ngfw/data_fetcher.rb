class Ngfw::DataFetcher
  class << self
    SOURCE_FILE_URL = 'http://feeds.ironport.com/ngfw/data/uncat_detail.txt'.freeze

    def fetch
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
