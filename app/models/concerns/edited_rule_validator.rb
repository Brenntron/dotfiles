# Runs validations specific to edited rules.
# see validate method.
class EditedRuleValidator < ActiveModel::Validator

  # Runs validations specific to rules with edit status = 'EDIT'.
  # If a rule is not edited (it is new or synched), no errors are added.
  # So it treats those rules as valid here, to be validated elsewhere.
  #
  # @param [Rule] rule the record to validate.
  def validate(rule)
    return unless rule.edited_rule?

    rule.errors.add(:edit_status, 'must be EDIT') unless Rule::EDIT_STATUS_EDIT == rule.edit_status
    rule.errors.add(:publish_status, 'cannot be blank') unless rule.publish_status.present?
    rule.errors.add(:gid, 'must be 1') unless 1 == rule.gid
    rule.errors.add(:sid, 'cannot be blank') unless rule.sid.present?
    rule.errors.add(:rev, 'cannot be blank') unless rule.rev.present?

    # rule.errors.add(:rule_content, 'cannot be blank') unless rule.rule_content.present?
    rule.errors.add(:rule_parsed, 'cannot be blank') unless rule.rule_parsed.present?
    rule.errors.add(:cvs_rule_content, 'cannot be blank') unless rule.cvs_rule_content.present?
    rule.errors.add(:cvs_rule_parsed, 'cannot be blank') unless rule.cvs_rule_parsed.present?
  end
end
