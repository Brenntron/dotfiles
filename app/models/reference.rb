class Reference < ActiveRecord::Base
  has_many :bugs
  has_and_belongs_to_many :rules
  belongs_to :reference_type
  belongs_to :bug
  has_and_belongs_to_many :exploits

  after_create {|reference| reference.record 'create' if Rails.configuration.websockets_enabled == "true"}
  after_update {|reference| reference.record 'update' if Rails.configuration.websockets_enabled == "true"}
  after_destroy {|reference| reference.record 'destroy' if Rails.configuration.websockets_enabled == "true"}

  def record action
    record = { resource: 'reference',
               action: action,
               id: self.id,
               obj: self }
    PublishWebsocket.push_changes(record)
  end
end