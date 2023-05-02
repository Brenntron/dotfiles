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

  belongs_to :creator, class_name: 'User', foreign_key: :creator_id, optional: true
  belongs_to :editor, class_name: 'User', foreign_key: :editor_id, optional: true

  validates_presence_of :name, :ticket_type
  validates :body, presence: true, if: :in_progress?

  scope :for_disputes, -> { where(ticket_type: 'Dispute')}
  scope :by_resolution, ->(resolution) { for_snort_escalations.where(resolution_type: resolution)}

 end
 