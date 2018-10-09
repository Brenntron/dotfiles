module Escalations::Webrep::DisputesHelper
  def rule_trigger(rule_hit)
    if RulehitResolutionMailerTemplate.where(mnemonic: rule_hit.name).exists?
      link_to(rule_hit.name, '#', class: 'wbrs-rule-trigger', 'data-id' => rule_hit.id)
    else
      rule_hit.name
    end
  end
end
