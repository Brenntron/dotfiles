class Event < ApplicationRecord

  after_create { |event| event.record 'create' if Rails.configuration.websockets_enabled == 'true' }
  after_update { |event| event.record 'update' if Rails.configuration.websockets_enabled == 'true' }
  after_destroy { |event| event.record 'destroy' if Rails.configuration.websockets_enabled == 'true' }

  def record(action)
    record = { resource: 'event',
               action: action,
               id: self.id,
               obj: self }
    PublishWebsocket.push_changes(record)
  end
end
