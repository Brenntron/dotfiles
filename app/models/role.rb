class Role < ApplicationRecord
  has_and_belongs_to_many :users
  belongs_to :org_subset

  validates :role, presence: true, uniqueness: { case_sensitive: true }

  after_create { |role| role.record 'create' if Rails.configuration.websockets_enabled == 'true' }
  after_update { |role| role.record 'update' if Rails.configuration.websockets_enabled == 'true' }
  after_destroy { |role| role.record 'destroy' if Rails.configuration.websockets_enabled == 'true' }

  scope :exclude_admin, -> { where.not(role: 'admin') }

  def record(action)
    record = { resource: 'role',
               action: action,
               id: self.id,
               obj: self }
    PublishWebsocket.push_changes(record)
  end
end
