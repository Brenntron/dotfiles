class Event < ActiveRecord::Base

  after_create {|event| event.record 'create' }
  after_update {|event| event.record 'update' }
  after_destroy {|event| event.record 'destroy' }

  def record action
    record = { resource: 'event',
               action: action,
               id: self.id,
               obj: self }
    PublishWebsocket.push_changes(record)
  end

end