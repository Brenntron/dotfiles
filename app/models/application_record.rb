class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.humanize_secs(sec_input)
    mm, ss = sec_input.to_i.divmod(60)
    hh, mm = mm.divmod(60)
    dd, hh = hh.divmod(24)
    case
      when 366 < dd
        "#{dd / 365} years"
      when 56 <= dd
        "#{dd / 30} months"
      when 21 <= dd
        "#{dd / 7} weeks"
      when dd > 0
        "%id %ih" % [dd, hh]
      when hh > 0
        "%ih %im" % [hh, mm]
      else
        "%im %is" % [mm, ss]
    end
  end

  def humanize_secs(sec_input)
    ApplicationRecord.humanize_secs(sec_input)
  end
end
