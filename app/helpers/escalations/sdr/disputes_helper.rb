module Escalations::Sdr::DisputesHelper
  def dispute_age(assigned_at)
    return '' unless assigned_at
    age = assigned_at - DateTime.now
    age = age.abs # lazy
    mm, ss = age.divmod(60)
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

  def extract_details(description)
    return '' if description.nil?
    extracted_details = description.split(".\r")[0]
    extracted_details = extracted_details.split(',')
  end
end
