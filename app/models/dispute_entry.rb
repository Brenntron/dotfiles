class DisputeEntry < ApplicationRecord
  has_paper_trail on: [:update], ignore: [:updated_at]
  belongs_to :dispute
  has_many :dispute_rule_hits

  delegate :cvs_username, to: :dispute, allow_nil: true

  scope :resolved_date, -> (date_iso) {
    date_from = Date.iso8601(date_iso)
    date_to = Date.iso8601(date_iso) + 1
    where(case_resolved_at: (date_from..date_to))
  }

  def self.from_age_report_params(params)
    resolved_date(params['date'])
  end

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
    @classifications ||= blacklist&.classifications || []
  end

  def wbrs_list_type
    @wbrs_list_type ||= Wbrs::ManualWlbl.where(url: hostlookup).first&.list_type
  end

  def wbrs_xlist
    @wbrs_xlist ||= Wbrs::ManualWlbl.where(url: hostlookup)
  end

  def virustotals
    unless @virustotals
      scans = Virustotal::GetVirustotal.by_domain(hostlookup)["scans"]
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
end
