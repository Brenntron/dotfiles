class RuleCategory < ActiveRecord::Base
  has_many :rules

  validates :category, uniqueness: true
end