class Note < ActiveRecord::Base
  belongs_to :bug

  after_create {|note| note.record 'create' }
  after_update {|note| note.record 'update' }
  after_destroy {|note| note.record 'destroy' }

  def record action
    record = { resource: 'note',
               action: action,
               id: self.id,
               obj: self }
    PublishWebsocket.push_changes(record)
  end
end
