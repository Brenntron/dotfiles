class Reference < ActiveRecord::Base
  has_many :bugs
  has_and_belongs_to_many :rules
  belongs_to :reference_type
  belongs_to :bug
  has_and_belongs_to_many :exploits

  after_create {|reference| reference.record 'create' }
  after_update {|reference| reference.record 'update' }
  after_destroy {|reference| reference.record 'destroy' }

  def record action
    record = { resource: 'reference',
               action: action,
               id: self.id,
               obj: self }
    PublishWebsocket.push_changes(record)
  end
end