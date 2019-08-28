Delayed::Worker.sleep_delay = 45
Delayed::Worker.max_attempts = 12
Delayed::Worker.max_run_time = 5.minutes
Delayed::Worker.read_ahead = 5


class AccessDelayedJobWeb
  def self.matches?(request)
    user = request.env['REMOTE_USER'] ||  Rails.configuration.backend_auth[:default_remote_user]
    current_user = User.where(cvs_username: user).first
    return false if current_user.blank?
    Ability.new(current_user).can? :manage, Admin
  end
end