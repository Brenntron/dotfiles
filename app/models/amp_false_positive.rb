class AmpFalsePositive < ApplicationRecord
  has_paper_trail on: [:update], ignore: [:updated_at]
  belongs_to :user, :optional => true
  belongs_to :customer, :optional => true

  AC_SUCCESS = 'CREATE_ACK'
  AC_FAILED = 'CREATE_FAILED'
  AC_PENDING = 'CREATE_PENDING'

  TI_NEW = 'PENDING'
  TI_RESOLVED = 'RESOLVED'
  TI_CLOSED = 'CLOSED'

  def self.process_bridge_payload(message_payload)
    begin
      ActiveRecord::Base.transaction do
        a = message_payload["payload"]
        binding.pry
      end
    end
  end

end