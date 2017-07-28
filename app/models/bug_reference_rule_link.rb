class BugReferenceRuleLink < ApplicationRecord
  belongs_to :reference
  belongs_to :link, polymorphic: true
end