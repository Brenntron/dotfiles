class Xbrs::GetXbrs < Xbrs::Base


  def self.all
    call_xbrs_request(:get, "/v1/rules", body: {})
  end

  def self.by_domain(name)
    call_xbrs_request(:get, "/v1/domain/#{name}", body: {})
  end

  def self.by_mnemonic(name)
    call_xbrs_request(:get, "/v1/rules/#{name}", body: {})
  end

  def self.by_ip4(name)
    call_xbrs_request(:get, "/v1/ip/#{name}", body: {})
  end

  def self.system_stats
    call_xbrs_request(:get, "/v1/status", body: {})
  end

end