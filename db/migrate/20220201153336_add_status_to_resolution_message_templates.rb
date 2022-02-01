class AddStatusToResolutionMessageTemplates < ActiveRecord::Migration[5.2]
  RESOLVED_STATUSES = {
    Dispute::STATUS_RESOLVED_FIXED_FP => 'Talos has concluded that the submission is safe to access at this time; the submission’s reputation has been improved. This update will be publicly visible in the next 24 hours.',
    Dispute::STATUS_RESOLVED_FIXED_FN => 'Talos has concluded that the submission is unsafe to access at this time due to malicious activity; the submission’s reputation has been decreased. This update will be publicly visible in the next 24 hours.',
    Dispute::STATUS_RESOLVED_UNCHANGED => 'Talos has not found sufficient evidence to modify the current reputation of the submission; we cannot change the submission’s reputation because it can negatively affect our customers. However, a customer has the option of locally changing a submission’s reputation, if they understand the risks in doing so.',
    Dispute::STATUS_RESOLVED_INVALID => '',
    Dispute::STATUS_RESOLVED_TEST => '',
    Dispute::STATUS_RESOLVED_OTHER => ''
  }.freeze

  def up
    add_column :resolution_message_templates, :status, :integer, default: 0
    RESOLVED_STATUSES.each do |name, description|
      ResolutionMessageTemplate.create(name: ResolutionMessageTemplate::DISPLAY_STATUS_NAMES[name], body: description, status: :resolved)
    end
  end

  def down
    ResolutionMessageTemplate.where(status: :resolved).destroy_all
    remove_column :resolution_message_templates, :status
  end
end
