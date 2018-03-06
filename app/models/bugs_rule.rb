class BugsRule < ApplicationRecord
  belongs_to :bug
  belongs_to :rule

  scope :from_summary, -> { where(in_summary: true) }
end
