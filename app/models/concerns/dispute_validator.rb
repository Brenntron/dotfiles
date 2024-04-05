class DisputeValidator < ActiveModel::Validator
  def validate(dispute)
    unless dispute.is_assigned? || [ Dispute::STATUS_NEW, Dispute::STATUS_RESOLVED, Dispute::PROCESSING ].include?(dispute.status)
      dispute.errors.add(:user_id, 'must be assigned unless NEW or RESOLVED_CLOSED or PROCESSING')
    end
  end
end
