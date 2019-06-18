class WbnpReport < ApplicationRecord
  ACTIVE = "active"
  COMPLETE = "complete"
  ERROR = "error"

  scope :active_reports, -> { where(status: ACTIVE)}


  def self.null_report
    {:id => nil, :total_new_cases => 0, :cases_imported => 0, :cases_failed => 0, :status => COMPLETE, :notes => ""}
  end
end
