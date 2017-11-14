# Runs validations specific to new rules.
# see validate method.
class SnortRuleValidator < ActiveModel::Validator

  # Runs validations specific to rules with edit status = 'NEW'.
  # If a rule is not new, no errors are added.
  # So it treats those rules as valid here, to be validated elsewhere.
  #
  # @param [Rule] rule the record to validate.
  def validate(rule)
    return unless 1 == rule.gid

    rule.errors.add(:state, 'cannot be blank') unless rule.state.present?
    rule.errors.add(:rule_content, 'cannot be blank') unless rule.rule_content.present?
    rule.errors.add(:connection, 'cannot be blank') unless rule.connection.present?
    rule.errors.add(:message, 'cannot be blank') unless rule.message.present?
    rule.errors.add(:rule_category_id, 'cannot be blank') unless rule.rule_category_id.present?

  end
end
