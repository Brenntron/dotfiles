class DisputeEntry < ApplicationRecord
  belongs_to :dispute
  has_many :dispute_rule_hits
end
