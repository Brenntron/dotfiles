# Mixin for generic web service requester for web service APIs that we call.
module ApiRequester::ApiRequester
  def self.config_of(hash)
    result = OpenStruct.new
    %w{host verify_mode port gssnegotiate ca_cert_file api_key}.each do |key|
      result.send((key + '=').to_sym, hash[key])
    end
    result
  end
end
