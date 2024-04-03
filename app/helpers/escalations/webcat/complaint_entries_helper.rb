module Escalations::Webcat::ComplaintEntriesHelper
  def complaint_entry_age(complaint_entry)
    created_at_in_words = time_ago_in_words(complaint_entry.created_at.to_time, { scope: 'datetime.distance_in_words', include_seconds: false })
    ComplaintEntry.first_two_time_layers(created_at_in_words)
  end


    end
  end

  def search_condition_json(named_search)
    named_search.named_search_criteria.pluck(:field_name, :value).to_h.to_json
  end
end
