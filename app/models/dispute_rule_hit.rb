class DisputeRuleHit < ApplicationRecord
  belongs_to :dispute_entry

  scope :wbrs_rule_hits, -> { where(rule_type: 'WBRS') }
  scope :sbrs_rule_hits, -> { where(rule_type: 'SBRS') }
end
