class EscalationLink < ApplicationRecord
  belongs_to :snort_research_bug, class_name: "Bug"
  belongs_to :snort_escalation_bug, class_name: "Bug"
  
  def process_bridge_payload

  end
end
