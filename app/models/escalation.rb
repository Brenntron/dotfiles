class Escalation < ApplicationRecord
  belongs_to :snort_research_escalation_bug, class_name: "Bug"
  belongs_to :snort_escalation_research_bug, class_name: "Bug"
end
