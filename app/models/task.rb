class Task < ActiveRecord::Base
  belongs_to :bug
  belongs_to :user
  has_many :rules
  has_many :attachments

  after_create {|task| task.record 'create' if Rails.configuration.websockets_enabled == "true"}
  after_update {|task| task.record 'update' if Rails.configuration.websockets_enabled == "true"}
  after_destroy {|task| task.record 'destroy' if Rails.configuration.websockets_enabled == "true"}

  def record action
    record = { resource: 'task',
               action: action,
               id: self.id,
               obj: self }
    PublishWebsocket.push_changes(record)
  end

end