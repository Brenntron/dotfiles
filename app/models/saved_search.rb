class SavedSearch < ApplicationRecord
  belongs_to :user

  validates :project_type, presence: true

  scope :by_escalations, -> { where(:product => "escalations")}
  scope :by_default, -> { where(:product => nil)}
end
