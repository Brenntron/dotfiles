class Job < ActiveRecord::Base
  belongs_to :bug
  belongs_to :user
  has_many :rules
  has_many :attachments

  after_create {|job| job.record 'create' }
  after_update {|job| job.record 'update' }
  after_destroy {|job| job.record 'destroy' }

  def record action
    record = { resource: 'job',
               action: action,
               id: self.id,
               obj: self }
    PublishWebsocket.push_changes(record)
  end

end