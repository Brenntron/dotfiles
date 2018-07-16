class Virustotal::GetVirustotal < Virustotal::Base

  def self.load_from_prefetch(data)
    response_body = JSON.parse(data)
    response_body
  end

  def self.by_domain(url, raw = false)
    call_virustotal_request(:get, "/vtapi/v2/url/report?resource=#{url}", {}, raw)
  end

end
