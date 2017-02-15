class RuleCategory < ApplicationRecord
  has_many :rules

  validates :category, uniqueness: true
end
