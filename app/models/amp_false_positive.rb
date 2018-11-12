class AmpFalsePositive < ApplicationRecord
  has_paper_trail on: [:update], ignore: [:updated_at]
  belongs_to :user, :optional => true
  belongs_to :customer, :optional => true
  has_many :amp_false_positive_files

  AC_SUCCESS         = 'CREATE_ACK'
  AC_FAILED          = 'CREATE_FAILED'
  AC_PENDING         = 'CREATE_PENDING'

  TI_NEW             = 'PENDING'
  TI_RESOLVED        = 'RESOLVED'
  TI_CLOSED          = 'CLOSED'

  NEW                = "NEW"
  RESOLVED           = "RESOLVED"
  ASSIGNED           = 'ASSIGNED'
  ACTIVE             = 'ACTIVE'
  COMPLETED          = 'COMPLETED'
  PENDING            = 'PENDING'
  DUPLICATE          = "DUPLICATE"


  def self.process_bridge_payload(message_payload)
    begin
      ActiveRecord::Base.transaction do
        payload = message_payload["payload"]

        self.amp_false_positive_files << AmpFalsePositiveFile.new(payload[file])
        self.customer = Customer.find_or_create_by_email(payload[user][email]) #also use organization if possible
        self.sha256 = message_payload['sha256']
        self.source = message_payload['source']
        self.description = payload['comment']['text']
        self.product = payload['source']['name']
        self.sr_id = message_payload['sr_id']
        self.status = NEW



      end
    end
  end

  def ti_status
    RESOLVED == status ? AmpFalsePositive::TI_RESOLVED : AmpFalsePositive::TI_NEW
  end

end