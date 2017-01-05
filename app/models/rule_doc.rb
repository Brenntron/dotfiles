class RuleDoc < ActiveRecord::Base
  belongs_to :rule

  validates :summary, presence: true

  before_create :compose_impact, if: Proc.new { |doc| doc.impact.blank? }

  def compose_impact
    self.impact = self.rule.rule_classification
  end
end
