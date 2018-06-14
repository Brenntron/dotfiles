class Complaint < ApplicationRecord
  belongs_to :user
  has_many :complaint_entries
end



