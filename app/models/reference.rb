class Reference < ApplicationRecord
  belongs_to :reference_type, optional: true
  has_and_belongs_to_many :exploits

  has_many :bug_reference_rule_links
  has_many :rules, through: :bug_reference_rule_links, source: :link, source_type: "Rule"
  has_many :bugs, through: :bug_reference_rule_links, source: :link, source_type: "Bug"
  has_many :references, through: :bug_reference_rule_links, source: :link, source_type: "Reference"
  has_many :cves

  validates :reference_data, uniqueness: { scope: :reference_type_id }

  after_create { |reference| reference.record 'create' if Rails.configuration.websockets_enabled == 'true' }
  after_update { |reference| reference.record 'update' if Rails.configuration.websockets_enabled == 'true' }
  after_destroy { |reference| reference.record 'destroy' if Rails.configuration.websockets_enabled == 'true' }

  scope :cves,          -> { where(reference_type: ReferenceType.cve) }
  scope :bugtraqs,      -> { where(reference_type: ReferenceType.bugtraq) }
  scope :telus,         -> { where(reference_type: ReferenceType.telus) }
  scope :apsb,          -> { where(reference_type: ReferenceType.apsb) }
  scope :urls,          -> { where(reference_type: ReferenceType.url) }
  scope :msb,           -> { where(reference_type: ReferenceType.msb) }
  scope :osvdb,         -> { where(reference_type: ReferenceType.osvdb) }

  delegate(:name, to: :reference_type, prefix: true, allow_nil: true)

  def record(action)
    record = { resource: 'reference',
               action: action,
               id: self.id,
               obj: self }
    PublishWebsocket.push_changes(record)
  end
end
