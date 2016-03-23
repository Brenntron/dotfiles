class LocalJob < ActiveRecord::Base
  belongs_to :bug
  belongs_to :user
  has_many :rules
  has_many :attachments

  after_create {|local_job| local_job.record 'create' if Rails.configuration.websockets_enabled == "true"}
  after_update {|local_job| local_job.record 'update' if Rails.configuration.websockets_enabled == "true"}
  after_destroy {|local_job| local_job.record 'destroy' if Rails.configuration.websockets_enabled == "true"}

  def record action
    record = { resource: 'local_job',
               action: action,
               id: self.id,
               obj: self }
    PublishWebsocket.push_changes(record)
  end

end