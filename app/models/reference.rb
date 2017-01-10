class Reference < ActiveRecord::Base
  has_many :bugs
  has_and_belongs_to_many :rules
  belongs_to :reference_type
  belongs_to :bug
  has_and_belongs_to_many :exploits

  after_create { |reference| reference.record 'create' if Rails.configuration.websockets_enabled == 'true' }
  after_update { |reference| reference.record 'update' if Rails.configuration.websockets_enabled == 'true' }
  after_destroy { |reference| reference.record 'destroy' if Rails.configuration.websockets_enabled == 'true' }

  scope :cves, ->     { where('reference_type_id=?', ReferenceType.find_by_name('cve').id) }
  scope :bugtraqs, -> { where('reference_type_id=?', ReferenceType.find_by_name('bugtraq').id) }
  scope :telus, ->    { where('reference_type_id=?', ReferenceType.find_by_name('telus').id) }
  scope :apsb, ->     { where('reference_type_id=?', ReferenceType.find_by_name('apsb').id) }
  scope :urls, ->     { where('reference_type_id=?', ReferenceType.find_by_name('url').id) }
  scope :msb, ->      { where('reference_type_id=?', ReferenceType.find_by_name('msb').id) }
  scope :osvdb, ->    { where('reference_type_id=?', ReferenceType.find_by_name('osvdb').id) }

  def record(action)
    record = { resource: 'reference',
               action: action,
               id: self.id,
               obj: self }
    PublishWebsocket.push_changes(record)
  end
end
