require 'resolv'

class Preloader::Base
  include ActiveModel::Model

  def self.fetch_all_api_data(host, dispute_entry_id) # pass an entire DisputeEntry into this

    is_ip_address = !!(host  =~ Resolv::IPv4::Regex)

    blacklist ||= RepApi::Blacklist.where({entries: [ host ]}, true)#.first
    virustotals ||= Virustotal::GetVirustotal.by_domain(host, true)
    crosslisted_urls ||= Wbrs::ManualWlbl.where({url: host}, true)
    wbrs_list_type ||= Wbrs::ManualWlbl.where(url: host).first&.list_type

    if is_ip_address === true
      xbrs_history = Xbrs::GetXbrs.by_ip4(host, true)
    else
      xbrs_history = Xbrs::GetXbrs.by_domain(host, true)
    end

    dispute_entry = DisputeEntry.find(dispute_entry_id)
    if dispute_entry.dispute_entry_preload.present?
      preload = dispute_entry.dispute_entry_preload
      preload.destroy
      dispute_entry.reload
    end

    data = DisputeEntryPreload.new do |d|
      d.dispute_entry_id = dispute_entry_id
      d.xbrs_history = xbrs_history
      d.crosslisted_urls = crosslisted_urls
      d.virustotal = virustotals
      d.wlbl = blacklist
      d.wbrs_list_type = wbrs_list_type
    end

    data.save!

  end
end
