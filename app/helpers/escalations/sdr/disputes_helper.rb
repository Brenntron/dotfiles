module Escalations::Sdr::DisputesHelper
  def dispute_age(created_at)
    seconds_diff = (Time.zone.now - created_at).to_i.abs

    hours = seconds_diff / 3600
    seconds_diff -= hours * 3600

    minutes = seconds_diff / 60
    seconds_diff -= minutes * 60

    seconds = seconds_diff

    '%02dhr %02dmin' % [hours, minutes]
  end
end
