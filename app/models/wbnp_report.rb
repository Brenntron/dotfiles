class WbnpReport < ApplicationRecord
  ACTIVE = "active"
  COMPLETE = "complete"
  ERROR = "error"

  scope :active_reports, -> { where(status: ACTIVE)}
end
