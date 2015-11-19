class Note < ActiveRecord::Base
  belongs_to :bug

  after_create {|note| note.record 'create' if Rails.configuration.websockets_enabled == "true"}
  after_update {|note| note.record 'update' if Rails.configuration.websockets_enabled == "true"}
  after_destroy {|note| note.record 'destroy' if Rails.configuration.websockets_enabled == "true"}

  def record action
    record = { resource: 'note',
               action: action,
               id: self.id,
               obj: self }
    PublishWebsocket.push_changes(record)
  end
end
