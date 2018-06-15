class Customer < ApplicationRecord
  belongs_to :company
  has_many :complaints
  has_many :disputes
end