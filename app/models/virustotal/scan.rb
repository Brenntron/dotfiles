class Virustotal::Scan < Virustotal::Base
  def self.scan_query_string(address:)
    "apikey=#{Rails.configuration.virus_total.api_key}&resource=#{address}"
  end

  def self.full_scan_url(address:)
    "#{Rails.configuration.virus_total.url}?#{scan_query_string(address: address)}"
  end

  def self.virus_total_request(address:)
    request = HTTPI::Request.new(full_scan_url(address: address))
    byebug
    request.ssl = true
    request.auth.ssl.verify_mode = :peer
    request.headers['Content-Type'] = 'application/x-www-form-urlencoded'
    request
  end

  def self.scan_hashes

  end
end
