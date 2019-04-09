# class FileReputationTicket < ApplicationRecord
class FileReputationDispute < ApplicationRecord
  belongs_to :customer, optional:true
  delegate :name, :company, :company_id, to: :customer, allow_nil: true, prefix: true

  STATUS_NEW                = 'NEW'
  STATUS_ASSIGNED           = 'ASSIGNED'
  STATUS_CLOSED             = 'CLOSED'

  DISPOSITION_MALICIOUS     = 'MALICIOUS'

  validates :status, :file_name, :sha256_hash, :disposition_suggested, presence: true

  def update_status(status)
    self.update!(status: status)

    envelope = {}

    envelope[:addressee_id] = self.id
    envelope[:addressee_status] = self.status

    Bridge::FilerepUpdateStatusEvent.new(envelope).post
  end
end
