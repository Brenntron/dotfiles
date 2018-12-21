class Beaker::Verdicts < Beaker::Base

  def self.verdicts(domains, raw = false)
    urls_list = []
    ips_list = []
    domains.each do |d|
      is_ip_address = !!(d =~ Resolv::IPv4::Regex)
      if is_ip_address
        ips_list << d
      else
        urls_list << d
      end
    end

    domain_lookup_package = [
        :url => urls_list,
        :ip => ips_list
    ]

    call_beaker_request(:get, "/verdicts", domain_lookup_package, raw)
  end

end
