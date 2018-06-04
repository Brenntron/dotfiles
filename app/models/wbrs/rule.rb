class Wbrs::Rule < Wbrs::Base
  attr_accessor :category_id, :desc_long, :descr, :domain, :is_active, :mnem, :path, :path_hashed, :port, :prefix_id,
                :protocol, :subdomain, :truncated

  def active?
    is_active
  end

  def truncated?
    truncated
  end

  def self.new_from_datum(datum)
    datum['category_id'] = datum.delete('category')
    new(datum)
  end

  def self.get_where(categories: nil)
    response = post_request(path: '/v1/cat/rules/get', body: {"categories": categories })

    response_body = JSON.parse(response.body)
    response_body['data'].map {|datum| new_from_datum(datum)}
  end
end
