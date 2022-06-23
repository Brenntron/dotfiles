class AppConfig

  def self.auto_resolve_toggle
    redis = Redis.new
    toggle = redis.get('auto_resolve_toggle')
    if toggle.blank?
      redis.set('auto_resolve_toggle', Rails.configuration.auto_resolve.check_complaints)
      toggle = redis.get('auto_resolve_toggle')
    end

    toggle
  end

  def self.matching_disposition_toggle
    redis = Redis.new
    toggle = redis.get('matching_disposition_toggle')
    if toggle.blank?
      redis.set('matching_disposition_toggle', Rails.configuration.auto_resolve.check_matching_disposition)
    end

    toggle
  end

end
