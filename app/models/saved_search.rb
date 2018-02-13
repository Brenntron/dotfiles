class SavedSearch < ApplicationRecord
  belongs_to :user

  scope :by_escalations, -> { where(:product => "escalations")}
  scope :by_default, -> { where(:product => nil)}
end
