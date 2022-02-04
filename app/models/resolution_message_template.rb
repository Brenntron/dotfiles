class ResolutionMessageTemplate < ApplicationRecord
  DISPLAY_STATUS_NAMES = {
    Dispute::STATUS_RESOLVED_FIXED_FP => 'Fixed - FP',
    Dispute::STATUS_RESOLVED_FIXED_FN => 'Fixed - FN',
    Dispute::STATUS_RESOLVED_UNCHANGED => 'Unchanged',
    Dispute::STATUS_RESOLVED_INVALID => 'Invalid / Junk Mail',
    Dispute::STATUS_RESOLVED_TEST => 'Test / Training',
    Dispute::STATUS_RESOLVED_OTHER => 'Other'
}.freeze

  enum status: { in_progress: 0, resolved: 1 }

  validates_presence_of :name
  validates :body, presence: true, if: :status_in_progress?
  validate :resolved_message?
  private
 
  def status_in_progress?
    [:status] == 'in_progres'
  end

  def resolved_message?
    if self.status_in_progress? && (name_chanded? || description_chanded?)
      errors.add(:base, "You can't change name or description for 'Resolved / Closed' messages")
    end
  end
 end
