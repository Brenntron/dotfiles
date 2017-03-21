class Alert < ApplicationRecord
  belongs_to :attachment
  belongs_to :rule

  TEST_GROUP_PCAP   = 'pcap'
  TEST_GROUP_LOCAL  = 'local'

  scope :pcap_alerts, -> { where(test_group: Alert::TEST_GROUP_PCAP) }
  scope :local_alerts, -> { where(test_group: Alert::TEST_GROUP_LOCAL) }
  scope :by_rule, ->(rule) { where(rule: rule) }
end
