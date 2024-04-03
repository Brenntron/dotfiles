module Escalations::Webcat::ComplaintEntriesHelper
  def complaint_entry_age(complaint_entry)
    created_at_in_words = time_ago_in_words(complaint_entry.created_at.to_time, { scope: 'datetime.distance_in_words', include_seconds: false })
    ComplaintEntry.first_two_time_layers(created_at_in_words)
  end

  def search_condition_json(named_search)
    named_search.named_search_criteria.pluck(:field_name, :value).to_h.to_json
  end

  def wbrs_score_icon(score)
    if score.nil?
      'icon-unknown'
    elsif score <= -6
      'icon-untrusted'
    elsif score <= -3
      'icon-questionable'
    elsif score <= 0
      'icon-neutral'
    elsif score < 6
      'icon-favorable'
    elsif score >= 6
      'icon-trusted'
    end
  end

  def suggested_categories(categories)
    if categories.nil?
      return content_tag :p, class: 'missing-data', id: 'ce_suggested_categories' do
        'No suggested categories available.'
      end
    end

    cleaned_cats = []
    sugg_cats = categories.split(',')

    sugg_cats.each do |cat|
      # weird hack below, feel free to change
      unless cat == 'Not in our list'
        cleaned_cats.push(cat)
      end
    end

    content_tag :p, id: 'ce_suggested_categories' do
      cleaned_cats.join(', ')
    end
  end
end
