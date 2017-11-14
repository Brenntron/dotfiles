# Runs validations specific to synched rules.
# see validate method.
class SynchedRuleValidator < ActiveModel::Validator

  # Runs validations specific to rules with edit status = 'SYNCHED'.
  # If a rule is not synched, no errors are added.
  # So it treats those rules as valid here, to be validated elsewhere.
  #
  # @param [Rule] rule the record to validate.
  def validate(rule)
    return unless rule.synched_rule?
    return if rule.gid.nil?

    rule.errors.add(:edit_status, 'must be SYNCHED') unless Rule::EDIT_STATUS_SYNCHED == rule.edit_status
    rule.errors.add(:publish_status, 'must be SYNCHED') unless Rule::PUBLISH_STATUS_SYNCHED == rule.edit_status
    rule.errors.add(:gid, 'cannot be blank') unless rule.gid.present?
    rule.errors.add(:sid, 'cannot be blank') unless rule.sid.present?
    rule.errors.add(:rev, 'cannot be blank') unless rule.rev.present?

    # rule.errors.add(:rule_content, 'cannot be blank') unless rule.rule_content.present?
    if 1 == rule.gid
      rule.errors.add(:rule_parsed, 'cannot be blank') unless rule.rule_parsed.present?
    end
    rule.errors.add(:cvs_rule_content, 'must match rule_content') unless rule.rule_content == rule.cvs_rule_content
    rule.errors.add(:cvs_rule_parsed, 'must match rule_parsed') unless rule.rule_parsed == rule.cvs_rule_parsed
  end
end
