class SnortResearch < ApplicationRecord
  belongs_to :bug
  belongs_to :snort_research_to_research_bug, class_name: "Bug"
end
