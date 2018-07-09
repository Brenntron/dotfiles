class Virustotal::Scan < Virustotal::Base
  def self.scan_query_string(address:)
    byebug
    "apikey=#{Rails.configuration.virus_total.api_key}&resource=#{address}"
  end

  def self.full_scan_url(address:)
    "#{Rails.configuration.virus_total.url}?#{scan_query_string(address: address)}"
  end

  def self.scan_hashes

  end
end
