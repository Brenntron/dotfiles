require 'resolv'

class Preloader::Base
  include ActiveModel::Model

  def self.fetch_all_api_data(host, dispute_entry_id) # pass an entire DisputeEntry into this

    is_ip_address = !!(host  =~ Resolv::IPv4::Regex)

    blacklist ||= RepApi::Blacklist.where(entries: [ host ]).first
    virustotals ||= Virustotal::GetVirustotal.by_domain(host)
    crosslisted_urls ||= Wbrs::ManualWlbl.where(url: host)

    if is_ip_address === true
      xbrs_history = Xbrs::GetXbrs.by_ip4(host)
    else
      xbrs_history = Xbrs::GetXbrs.by_domain(host)
    end


    data = DisputeEntryPreload.new do |d|
      d.dispute_entry_id = dispute_entry_id
      d.xbrs_history = xbrs_history
      d.crosslisted_urls = crosslisted_urls
      d.virustotal = virustotals
      d.wlbl = blacklist
    end

    data.save!

  end
end
