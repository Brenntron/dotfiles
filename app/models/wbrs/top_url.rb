class Wbrs::TopUrl < Wbrs::Base
  FIELD_NAMES = %w{url is_important}
  FIELD_SYMS = FIELD_NAMES.map{|name| name.to_sym}

  attr_accessor *FIELD_SYMS

  def self.new_from_datum(datum)
    new(datum)
  end

  # Find out if an array of 1 or more urls are in Top URLs
  # @return [Array<Wbrs::TopUrl] Array of the results.
  def self.check_urls(urls = [])
    url_params = {}
    url_params[:urls] = urls
    response = call_json_request(:post, '/v1/cat/urls/top', body: url_params)

    response_body = JSON.parse(response.body)
    @all = response_body.map {|datum, important| new_from_datum({:url => datum, :is_important => important})}

    @all
  end

end
