class Virustotal::GetVirustotal < Virustotal::Base

  def self.by_domain(url)
    call_virustotal_request(:get, "/vtapi/v2/url/report?resource=#{url}", body: {})
  end

end
