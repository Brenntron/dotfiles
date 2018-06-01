class NamedSearchCriterion < ApplicationRecord

  belongs_to :named_search

  validates :named_search_id, :field_name, :value, presence: true

end
