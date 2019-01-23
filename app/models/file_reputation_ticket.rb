class FileReputationTicket < ApplicationRecord

  belongs_to :reputation_file, optional:true
  belongs_to :customer
  delegate :name,:customer_id, to: :customer, allow_nil: true, prefix: true
  delegate :sha256,:file_name,:file_path,:bugzilla_attachment_id, to: :reputation_file, allow_nil: true

end