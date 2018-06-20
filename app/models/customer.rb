class Customer < ApplicationRecord
  belongs_to :company
  has_many :complaints
  has_many :disputes

  validates :email, presence: true, uniqueness: true
end