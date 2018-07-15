class DisputeEntry < ApplicationRecord
  has_paper_trail on: [:update], ignore: [:updated_at]
  belongs_to :dispute
  has_many :dispute_rule_hits
  has_one  :dispute_entry_preload

  def hostlookup
    case
    when self.entry_type == "IP"
      self.ip_address
    when self.entry_type == "URI/DOMAIN"
      self.uri
    else
      self.uri.blank? ? self.ip_address : self.uri
    end
  end

  def find_xbrs
    if dispute_entry_preload.xbrs_history.present?
      return Xbrs::GetXbrs.load_from_prefetch(dispute_entry_preload.xbrs_history)
    end
    case
    when self.entry_type == "IP"
      Xbrs::GetXbrs.by_ip4(self.ip_address)
    when self.entry_type == "URI/DOMAIN"
      Xbrs::GetXbrs.by_domain(self.uri)
    else
      self.uri.blank? ? Xbrs::GetXbrs.by_ip4(self.ip_address) : Xbrs::GetXbrs.by_domain(self.uri)
    end
  end

  def blacklist(reload: false)
    if reload == false
      if dispute_entry_preload.wlbl.present?
        @blacklist = RepApi::Blacklist.load_from_prefetch(dispute_entry_preload.wlbl).first
        return @blacklist 
      end
    end
    @blacklist = nil if reload
    @blacklist ||= RepApi::Blacklist.where(entries: [ hostlookup ]).first
  end

  def classifications
    @classifications ||= blacklist&.classifications || []
  end

  def wbrs_list_type
    @wbrs_list_type = dispute_entry_preload.wbrs_list_type
    return @wbrs_list_type if @wbrs_list_type.present?

    #@wbrs_list_type ||= Wbrs::ManualWlbl.where(url: hostlookup).first&.list_type
    return nil
  end

  def wbrs_xlist
    if dispute_entry_preload.crosslisted_urls.present?
      @wbrs_xlist = Wbrs::ManualWlbl.load_from_prefetch(dispute_entry_preload.crosslisted_urls)
      return @wbrs_xlist
    end
    @wbrs_xlist ||= Wbrs::ManualWlbl.where(url: hostlookup)
  end

  def virustotals
    #@virustotals = self.virustotal
    #return @virustotals if @virustotals.present?

    unless @virustotals
      if dispute_entry_preload.virustotal.present?
        virustotal_data = Virustotal::GetVirustotal.load_from_prefetch(dispute_entry_preload.virustotal)
      else
        virustotal_data = Virustotal::GetVirustotal.by_domain(hostlookup)
      end
      #scans = Virustotal::GetVirustotal.by_domain(hostlookup)["scans"]
      scans = virustotal_data["scans"]
      cleandata = Array.new
      unless scans.nil?
        scans.each do |s|
          item = {:name => s[0], :result => s[1]["result"]}
          cleandata << item
        end
      end
      @virustotals = cleandata
    end
    @virustotals
  end

  def xbrs_data
    find_xbrs[1]
  end

end
