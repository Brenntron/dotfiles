# class FileReputationTicket < ApplicationRecord
class FileReputationDispute < ApplicationRecord
  belongs_to :customer, optional:true
  delegate :name, :company, :company_id, to: :customer, allow_nil: true, prefix: true

end
