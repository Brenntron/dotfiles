require 'uri'
require 'net/http'
require 'openssl'

class Virustotal::Scan < Virustotal::Base
  def self.scan_query_string(address:)
    "apikey=#{Rails.configuration.virustotal.api_key}&resource=#{address}"
  end

  def self.full_scan_url(address:)
    "#{Rails.configuration.virus_total.url}?#{scan_query_string(address: address)}"
  end

  def self.send_to_scan(address)
    url = URI("https://www.virustotal.com/api/v3/urls")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(url)
    request["Accept"] = 'application/json'
    request["Content-Type"] = 'application/x-www-form-urlencoded'
    request["x-apikey"] = self.api_key
    request.body = "url=#{address}"
    response = http.request(request)

  end

  def self.scan_hashes(address:)
    response = call_virustotal_request(:get,
                                       "/vtapi/v2/url/report?resource=#{address}",
                                       body: '',
                                       content_type: 'application/x-www-form-urlencoded')

    response
  end
end
