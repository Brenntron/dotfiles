class ResolutionMessageTemplate < ApplicationRecord
  DISPLAY_STATUS_NAMES = {
    Dispute::STATUS_RESOLVED_FIXED_FP => 'Fixed - FP',
    Dispute::STATUS_RESOLVED_FIXED_FN => 'Fixed - FN',
    Dispute::STATUS_RESOLVED_UNCHANGED => 'Unchanged',
    Dispute::STATUS_RESOLVED_INVALID => 'Invalid / Junk Mail',
    Dispute::STATUS_RESOLVED_TEST => 'Test / Training',
    Dispute::STATUS_RESOLVED_OTHER => 'Other'
  }

  enum status: { default: 0, resolved: 1 }

  validates_presence_of :name
  validates :body, presence: true, if: :status_default?
  
  private
  def status_default?
    [:status] == 'default'
  end
 end
