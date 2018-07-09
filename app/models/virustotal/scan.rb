class Virustotal::Scan < Virustotal::Base
  def self.scan_query_string(address:)
    byebug
    "apikey=#{Rails.configuration.virus_total.api_key}&resource=#{address}"
  end

  def self.scan_hashes

  end
end
