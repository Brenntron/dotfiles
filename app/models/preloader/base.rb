class Preloader::Base
  include ActiveModel::Model

  def fetch_all_api_data(host) # pass an entire DisputeEntry into this

    is_ip_address = !!(host  =~ Resolv::IPv4::Regex)

    blacklist ||= RepApi::Blacklist.where(entries: [ host ]).first
    virustotals ||= Virustotal::GetVirustotal.by_domain(host)
    crosslisted_urls ||= Wbrs::ManualWlbl.where(url: host)

    if is_ip_address === true
      xbrs_history = Xbrs::GetXbrs.by_ip4(self.ip_address)
    else
      xbrs_history = Xbrs::GetXbrs.by_domain(self.uri)
    end

  end
end
