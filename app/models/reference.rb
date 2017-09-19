class Reference < ApplicationRecord
  belongs_to :reference_type, optional: true
  has_and_belongs_to_many :exploits

  has_many :bug_reference_rule_links
  has_many :rules, through: :bug_reference_rule_links, source: :link, source_type: "Rule"
  has_many :bugs, through: :bug_reference_rule_links, source: :link, source_type: "Bug"
  
  validates :reference_data, uniqueness: { scope: :reference_type_id }

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

  delegate(:name, to: :reference_type, prefix: true, allow_nil: true)

  def record(action)
    record = { resource: 'reference',
               action: action,
               id: self.id,
               obj: self }
    PublishWebsocket.push_changes(record)
  end
end
