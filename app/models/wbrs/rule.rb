class Wbrs::Rule < Wbrs::Base
  attr_accessor :category, :desc_long, :descr, :domain, :is_active, :mnem, :path, :path_hashed, :port, :prefix_id,
                :protocol, :subdomain, :truncated

  def self.get_where(categories: nil)
    response = post_request(path: '/v1/cat/rules/get', body: {"categories": categories })
    Rails.logger.debug(">>> Wbrs::Rule.get #{response.inspect}")

    response_body = JSON.parse(response.body)
    response_body['data'].map {|datum| new(datum)}
  end
end
