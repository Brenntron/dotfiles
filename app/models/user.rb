class User < ApplicationRecord
  acts_as_nested_set

  has_many :bugs
  has_and_belongs_to_many :roles, dependent: :destroy

  validates :cvs_username, presence: true, uniqueness: true

  scope :has_cec, -> { where.not(cec_username: nil) }
  scope :not_user, ->(user_id) { where.not(id: user_id) }
  scope :allowed_assignees, ->(bug) { has_cec.not_user(bug.committer_id) }
  scope :allowed_committers, ->(bug) { has_cec.not_user(bug.user_id) }


  before_save :ensure_authentication_token
  after_create :add_role
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  enum class_level: {
                       unclassified: 0,
                       confidential: 1,
                       secret: 2,
                       top_secret: 3,
                       top_secret_sci: 4
                    }

  after_create { |user| user.record 'create' if Rails.configuration.websockets_enabled == 'true' }
  after_update { |user| user.record 'update' if Rails.configuration.websockets_enabled == 'true' }
  after_destroy { |user| user.record 'destroy' if Rails.configuration.websockets_enabled == 'true' }

  DEFAULT_METRICS_TIMEFRAME = 7

  scope :with_role, ->(role) { joins(:roles).where('roles.role = ?', role) }

  def self.search(conditions)
    # all
    name = conditions["name"]
    where("display_name like :name_pattern" +
              " or email like :name_pattern" +
              " or cvs_username like :name_pattern" +
              " or cec_username like :name_pattern" +
              " or kerberos_login like :name_pattern",
          name_pattern: "%#{name}%")
  end

  def record(action)
    record = { resource: 'user',
               action: action,
               id: self.id,
               obj: self }
    PublishWebsocket.push_changes(record)
  end

  def has_role?(role)
    roles.where(role: role).any?
  end

  def available_users
    User.all.reject{|u| self_and_ancestors.include?(u) ||
                        children.include?(u) ||
                        ['vrtincom', 'vrtqa'].include?(u.cvs_username) ||
                        u.cec_username.nil? }
  end

  def ensure_authentication_token
    if authentication_token.blank?
      self.authentication_token = generate_authentication_token
    end
  end

  def default_bug_list
    case
      when has_role?('committer')
        bugs.empty? ? Bug.pending : bugs.open_pending
      when has_role?('analyst')
        bugs.empty? ? Bug.open_pending : bugs.open_pending
      when has_role?('build coordinator')
        bugs.empty? ? Bug.where(state: 'FIXED').order(:resolved_at) : bugs.open_pending
      else
        Bug.all
    end
  end

  def authorized_user_list
    if has_role?('admin')
      User.all.map(&:id)
    else
      users = siblings + self_and_descendants
      [].tap { |arry| arry << users.map(&:id) }.flatten
    end
  end

  def authorized_to_see?(user_id)
    authorized_user_list.include?(user_id)
  end

  def team_metrics(bug_status)
    result = []
    descendants.each do |tm|
      bug_count = {}
      (chart_timeframe_preference.days.ago.to_date..Date.today).each do |day|
        bug_count[day.strftime('%b %d, %Y')] = tm.bugs.where("DATE(#{bug_status}_at) = ?", day).count
      end
      result << { "#{tm.cvs_username}" => bug_count }
    end
    result
  end

  def team_work_times
    descendants.map { |tm| { "#{tm.cvs_username}" => [tm.bugs.average(:work_time).try(:round) || 0,
                                                     tm.bugs.average(:rework_time).try(:round) || 0,
                                                     tm.bugs.average(:review_time).try(:round) || 0,
                                                     tm.average_resolution_times] } }
  end

  def average_resolution_times
    resolution_times = bugs.where('resolved_at is NOT ?', nil).map(&:resolution_time)
    resolution_times.empty? ? 0 : (resolution_times.sum / resolution_times.size).round()
  end

  def team_by_component(component)
    result = {}
    bugs = descendants.map { |tm| tm.bugs.by_component(component) }.flatten

    result[:work_time]       = bugs.map(&:work_time).compact
    result[:rework_time]     = bugs.map(&:rework_time).compact
    result[:review_time]     = bugs.map(&:review_time).compact
    result[:resolution_time] = bugs.map{ |x| x.resolution_time if x.resolution_time }.compact

    { "#{component}" => result.map { |k, v| ((v.inject { |sum, el| sum + el }.to_f / v.size).try(:round) unless v.empty?) || 0 } }
  end

  def chart_timeframe_preference
    metrics_timeframe ? metrics_timeframe : DEFAULT_METRICS_TIMEFRAME
  end

  private

  def add_role
    analyst = Role.where(role: 'analyst')
    roles << analyst unless roles.include?(analyst)
  end

  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.where(authentication_token: token).first
    end
  end

  def self.create_by_email(email)
    create(#kerberos_login: 'generated',
        cvs_username: email.split('@')[0],
        email: email,
        password: 'password',
        password_confirmation: 'password',
        committer: 'false')
  end

  # A user model from the db and or the http request.
  #
  # If there is no user in the database, a new User model is returned.
  # If the user is in the database, the NULL fields are set from the request.
  #
  # Our key for the user name is cvs_username.
  # This must be the name part of an email address used by bugzilla.
  # It must also be the remove user value sent from the web request.
  # This value is also stored as the kerberos_login field,
  # so the name part of a user's email address must match their kerberos login,
  # or our system will break.
  #
  # returns [User] the user model instance, but may be unsaved
  def self.from_request(params, request)
    remote_user =
        case
          when request.env['REMOTE_USER']
            request.env['REMOTE_USER']
          when Rails.configuration.backend_auth[:default_remote_user]
            Rails.configuration.backend_auth[:default_remote_user]
          else
            nil
        end
    raise Exception.new('You are not logged into Kerberos. Please try again.') unless remote_user
    remote_user = remote_user.sub(/@.*\z/, '')

    user_email =
      case
        when request.env['AUTHORIZE_MAIL']
          request.env['AUTHORIZE_MAIL']
        when Rails.configuration.backend_auth[:authenticate_email]
          Rails.configuration.backend_auth[:authenticate_email]
        else
          nil
      end

    user = User.where('cvs_username = ? OR email = ?', remote_user, user_email).first
    if user
      user.kerberos_login ||= remote_user
      user.email          ||= request.env['AUTHORIZE_MAIL'] || Rails.configuration.backend_auth[:authenticate_email]
      user.cec_username   ||= request.env['AUTHORIZE_CISCOCECUSERNAME'] || Rails.configuration.backend_auth[:authenticate_cec_username]
      user.display_name   ||= request.env['AUTHORIZE_DISPLAYNAME'] || Rails.configuration.backend_auth[:authenticate_display_name]
      user
    else
      user_attrs = {
          cvs_username:   remote_user,
          kerberos_login: remote_user,
          email:          request.env['AUTHORIZE_MAIL'] || Rails.configuration.backend_auth[:authenticate_email],
          cec_username:   request.env['AUTHORIZE_CISCOCECUSERNAME'] || Rails.configuration.backend_auth[:authenticate_cec_username],
          display_name:   request.env['AUTHORIZE_DISPLAYNAME'] || Rails.configuration.backend_auth[:authenticate_display_name],
          committer:      'false',
          class_level:    'unclassified',
          password:       'password',
          password_confirmation: 'password'
      }
      User.new(user_attrs)
    end
  end

  def self.login_user(params, request)
    begin
      user = from_request(params, request)
      if user
        user.confirmed = 'true'
        user.updated_at = Time.now
        user.ensure_authentication_token # make sure the user has a token generated
      end
      raise Exception.new('Error signing in. Please contact the administrator.') unless user&.save

      login_session = LoginSession.new(user)
      login_session.bugzilla_login
      login_session
    end
  end
end
