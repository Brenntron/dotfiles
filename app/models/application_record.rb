class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.log_exception(exception = $!)
    Rails.logger.error(exception.message)
    Rails.logger.error(exception.backtrace[0])
    Rails.logger.error(exception.backtrace[1])
    Rails.logger.error(exception.backtrace[2])
    Rails.logger.error(exception.backtrace[3])
    Rails.logger.error(exception.backtrace[4])
  end

  def log_exception(exception = $!)
    self.class.log_exception(exception)
  end

  def self.humanize_secs(sec_input)
    mm, ss = sec_input.to_i.divmod(60)
    hh, mm = mm.divmod(60)
    dd, hh = hh.divmod(24)
    case
      when 366 < dd
        "#{dd / 365} years, #{dd % 365} months"
      when 56 <= dd
        "#{dd / 30} months, #{dd % 30} days"
      when 21 <= dd
        "#{dd / 7} weeks #{dd % 7} days"
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
