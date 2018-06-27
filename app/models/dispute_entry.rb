class DisputeEntry < ApplicationRecord
  has_paper_trail on: [:update], ignore: [:updated_at]
  belongs_to :dispute
  has_many :dispute_rule_hits

  def hostlookup
    self.uri || self.hostname || self.ip_address
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
end
