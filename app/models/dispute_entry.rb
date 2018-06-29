class DisputeEntry < ApplicationRecord
  has_paper_trail on: [:update], ignore: [:updated_at]
  belongs_to :dispute
  has_many :dispute_rule_hits

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
    @blackist = nil if reload
    @blackist ||= RepApi::Blacklist.where(entries: [ hostlookup ]).first
  end

  def classifications
    blacklist&.classifications || []
  end

  def wbrs_list_type
    Wbrs::ManualWlbl.where(url: hostlookup).first&.list_type
  end

  def wbrs_xlist
    Wbrs::ManualWlbl.where(url: hostlookup)
  end
end
