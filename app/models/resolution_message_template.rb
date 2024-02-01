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

  scope :for_web_disputes, -> { where(ticket_type: 'WebDispute')}
  scope :for_email_disputes, -> { where(ticket_type: 'EmailDispute')}
  scope :for_file_reputation_disputes, -> { where(ticket_type: 'FileReputationDispute')}
  scope :for_sdr_disputes, -> { where(ticket_type: 'SenderDomainReputationDispute')}
  scope :for_webcat_disputes, -> { where(ticket_type: 'WebCategoryDispute')}

  scope :by_web_resolution_disputes, ->(resolution) { for_web_disputes.where(resolution_type: resolution)}
  scope :by_email_resolution_disputes, ->(resolution) { for_email_disputes.where(resolution_type: resolution)}
  scope :by_file_reputation_resolution_disputes, ->(resolution) { for_file_reputation_disputes.where(resolution_type: resolution)}
  scope :by_sdr_reputation_disputes, ->(resolution) { for_sdr_disputes.where(resolution_type: resolution)}
  scope :by_webcat_resolution_disputes, ->(resolution) { for_webcat_disputes.where(resolution_type: resolution)}

end
 