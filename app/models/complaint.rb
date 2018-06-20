class Complaint < ApplicationRecord
  belongs_to :user
  belongs_to :customer
  has_many :complaint_entries
end



