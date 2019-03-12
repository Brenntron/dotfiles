class DisputeValidator < ActiveModel::Validator
  def validate(dispute)
    unless dispute.is_assigned? || [ Dispute::STATUS_NEW, Dispute::STATUS_RESOLVED ].include?(dispute.status)
      dispute.errors.add(:user_id, 'must be assigned unless NEW or RESOLVED_CLOSED')
    end
  end
end
