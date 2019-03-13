class DisputeValidator < ActiveModel::Validator
  def validate(dispute)
    unless dispute.is_assigned? || [ Dispute::STATUS_NEW ].include?(dispute.status)
      dispute.errors.add(:user_id, 'must be assigned unless NEW')
    end
  end
end
