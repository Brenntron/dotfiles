class Whiteboard < ApplicationRecord
  has_many :giblets, as: :gib
  has_and_belongs_to_many :bugs

  validates :name, presence: true, uniqueness: { case_sensitive: true }
end
