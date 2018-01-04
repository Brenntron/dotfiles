class Tag < ApplicationRecord
  has_many :giblets, as: :gib
  has_and_belongs_to_many :bugs

  validates :name, presence: true, uniqueness: true

  after_create { |tag| tag.record 'create' if Rails.configuration.websockets_enabled == 'true' }
  after_update { |tag| tag.record 'update' if Rails.configuration.websockets_enabled == 'true' }
  after_destroy { |tag| tag.record 'destroy' if Rails.configuration.websockets_enabled == 'true' }

  def record(action)
    record = { resource: 'tag',
              action: action,
              id: self.id,
              obj: self }
    PublishWebsocket.push_changes(record)
  end
end
