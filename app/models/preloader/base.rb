require 'resolv'

class Preloader::Base
  include ActiveModel::Model
  TRIES = 3

  def self.auto_resolve_new
    AutoResolve.new
  end

  def self.fetch_all_api_data(host, dispute_entry_id) # pass an entire DisputeEntry into this

    is_ip_address = !!(host  =~ Resolv::IPv4::Regex)

    counter = 0
    while counter < TRIES
      begin
        blacklist ||= RepApi::Blacklist.where({entries: [ host ]}, true)
        break
      rescue
        counter = counter + 1
      end
    end
    counter = 0

    while counter < TRIES
      begin
        virustotals ||= Virustotal::GetVirustotal.by_domain(host, true)
        break
      rescue
        counter = counter + 1
      end
    end
    counter = 0

    # TODO refactor to call Wbrs::ManualWlbl.where once instead of twice
    while counter < TRIES
      begin
        crosslisted_urls ||= Wbrs::ManualWlbl.where({:url => host}, true)
        break
      rescue
        counter = counter + 1
      end
    end
    counter = 0

    while counter < TRIES
      begin
        wbrs_list_type ||= Wbrs::ManualWlbl.where({:url => host}).select{ |wlbl| wlbl.state == "active" && wlbl.url == self.hostlookup}.map{ |wlbl| wlbl.list_type }.join(', ')
        break
      rescue
        counter = counter + 1
      end
    end
    counter = 0

    while counter < TRIES
      begin
        if is_ip_address === true
          xbrs_history = Xbrs::GetXbrs.by_ip4(host, true)
        else
          xbrs_history = Xbrs::GetXbrs.by_domain(host, true)
        end
        break
      rescue
        counter = counter + 1
      end
    end

    while counter < TRIES
      begin
        @umbrella = auto_resolve_new.call_umbrella(address: host)
        pretty_umbrella_status = "Unclassified" # Default or "0"
        case
          # Per docs here: https://dashboard.umbrella.com/o/1755319/#overview
        when @umbrella[:status] == "-1"
          pretty_umbrella_status = "Malicious"
        when @umbrella[:status] == "1"
          pretty_umbrella_status = "Benign"
        end
        pretty_umbrella_status
        break
      rescue
        counter = counter + 1
      end
    end


    dispute_entry = DisputeEntry.find(dispute_entry_id)
    if dispute_entry.dispute_entry_preload.present?
      preload = dispute_entry.dispute_entry_preload
      preload.destroy
      dispute_entry.reload
    end

    # TODO: You know what, maybe this whole method should be in the DisputeEntryPreload class.
    data = DisputeEntryPreload.new do |d|
      d.dispute_entry_id = dispute_entry_id
      d.xbrs_history = xbrs_history
      d.crosslisted_urls = crosslisted_urls
      d.virustotal = virustotals
      d.wlbl = blacklist
      d.wbrs_list_type = wbrs_list_type
      d.umbrella = pretty_umbrella_status
    end

    data.save!

  end
end
