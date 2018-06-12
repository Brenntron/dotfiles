# Runs validations specific to new rules.
# see validate method.
class NewRuleValidator < ActiveModel::Validator

  # Runs validations specific to rules with edit status = 'NEW'.
  # If a rule is not new, no errors are added.
  # So it treats those rules as valid here, to be validated elsewhere.
  #
  # @param [Rule] rule the record to validate.
  def validate(rule)
    return unless rule.new_rule?

    rule.errors.add(:edit_status, 'must be NEW') unless Rule::EDIT_STATUS_NEW == rule.edit_status
    rule.errors.add(:publish_status, 'cannot be blank') unless rule.publish_status.present?
    rule.errors.add(:gid, 'must be 1') unless 1 == rule.gid
    rule.errors.add(:sid, 'must be blank') if rule.sid.present?
    rule.errors.add(:state, 'incorrect for edit_status NEW') unless %w{NEW FAILED}.include?(rule.state)

    # rule.errors.add(:rule_content, 'cannot be blank') unless rule.rule_content.present?
  end
end
