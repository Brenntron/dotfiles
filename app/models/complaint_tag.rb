class ComplaintTag < ApplicationRecord
  has_and_belongs_to_many :complaints

  validates :name, presence: true, uniqueness: { case_sensitive: true }
end