module Escalations::Webcat::ComplaintEntriesHelper
  def search_condition_json(named_search)
    named_search.named_search_criteria.pluck(:field_name, :value).to_h.to_json
  end
end
