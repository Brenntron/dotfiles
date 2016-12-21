class RuleDoc < ActiveRecord::Base
  belongs_to :rule

  validates :summary, presence: true
end