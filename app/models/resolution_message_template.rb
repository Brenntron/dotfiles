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

  validates_presence_of :name, :ticket_type
  validates :body, presence: true, if: :in_progress?
  validate :resolved_message?

  scope :for_disputes, -> { where(ticket_type: 'Dispute')}
  private

  def resolved_message?
    if resolved? && (name_changed? || description_changed?) && !new_record?
      errors.add(:base, "You can't change name or description for 'Resolved / Closed' messages")
    end
  end
 end
 