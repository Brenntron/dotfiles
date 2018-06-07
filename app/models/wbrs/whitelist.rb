class Wbrs::Whitelist < Wbrs::Base
  FIELD_NAMES = %w{entry source range ident comment}
  FIELD_SYMS = FIELD_NAMES.map{|name| name.to_sym}

  attr_accessor *FIELD_SYMS

  def self.new_from_attributes(attributes)
    new(attributes)
  end

  def self.where(conditions = {})
    # response = post_request(path: '/v1/cat/rules/get', body: stringkey_params(conditions))
    response = call_json_request(:post, '/v1/cat/rules/get', body: stringkey_params(conditions))

    response_body = JSON.parse(response.body)
    response_body.inject({}) do |collection_hash, (entry, value)|
      unless 'NOT_FOUND' == entry
        collection_hash[entry] = value.merge('entry' => entry)
      end

      collection_hash
    end.values.map{ |attributes| new_from_attributes(attributes) }

  rescue Wbrs::WbrsNotFoundError
    []
  end

end
