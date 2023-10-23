module Escalations::Webcat::ComplaintEntriesHelper
  def complaint_entry_age(assigned_at)
    return '' unless assigned_at

    age = assigned_at - DateTime.now
    age = age.abs # lazy
    mm, _ss = age.divmod(60)
    hh, mm = mm.divmod(60)
    dd, hh = hh.divmod(24)

    if dd > 0
      "%dd %dh" % [dd, hh]
    elsif hh > 0
      "%dh %dm" % [hh, mm]
    elsif hh == 0
      "<1 hr"
    end
  end

  def search_condition_json(named_search)
    named_search.named_search_criteria.pluck(:field_name, :value).to_h.to_json
  end
end
