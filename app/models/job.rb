class Job < ActiveRecord::Base
  belongs_to :bug
  belongs_to :user
  has_many :rules
  has_many :attachments

  after_create {|job| job.record 'create' if Rails.configuration.websockets_enabled == "true"}
  after_update {|job| job.record 'update' if Rails.configuration.websockets_enabled == "true"}
  after_destroy {|job| job.record 'destroy' if Rails.configuration.websockets_enabled == "true"}

  def record action
    record = { resource: 'job',
               action: action,
               id: self.id,
               obj: self }
    PublishWebsocket.push_changes(record)
  end

end