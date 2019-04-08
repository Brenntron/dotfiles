class Xbrs::GetXbrs < Xbrs::Base

  def self.load_from_prefetch(data)
    response_body = JSON.parse(data)
    response_body
  end

  def self.all
    call_xbrs_request(:get, "/v1/rules", body: {})
  end

  def self.by_domain(name, raw = false)
    name = CGI.escape(name)
    call_xbrs_request(:get, "/v1/domain/#{name}", {}, raw )
  end

  def self.by_mnemonic(name, raw = false)
    call_xbrs_request(:get, "/v1/rules/#{name}", {}, raw)
  end

  def self.by_ip4(name, raw = false)
    call_xbrs_request(:get, "/v1/ip/#{name}", {}, raw)
  end

  def self.system_stats
    call_xbrs_request(:get, "/v1/status", body: {})
  end

end
