class Virustotal::Scan < Virustotal::Base
  def self.scan_query_string(address:)
    "apikey=#{Rails.configuration.virus_total.api_key}&resource=#{address}"
  end

  def self.full_scan_url(address:)
    "#{Rails.configuration.virus_total.url}?#{scan_query_string(address: address)}"
  end


  def self.scan_hashes(address:)
    response = call_virustotal_request(:get,
                                       "/vtapi/v2/url/report&resource=#{address}",
                                       body: '',
                                       content_type: 'application/x-www-form-urlencoded')
    JSON.parse(response.body)
  end
end
