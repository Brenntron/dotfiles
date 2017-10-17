class Alert < ApplicationRecord
  belongs_to :attachment
  belongs_to :rule

  TEST_GROUP_PCAP   = 'pcap'
  TEST_GROUP_LOCAL  = 'local'

  scope :pcap_alerts, -> { where(test_group: Alert::TEST_GROUP_PCAP) }
  scope :local_alerts, -> { where(test_group: Alert::TEST_GROUP_LOCAL) }
  scope :by_rule, ->(rule) { where(rule: rule) }

  def self.reset_pcap(attachment)
    Alert.pcap_alerts.where(attachment: attachment).delete_all
  end

  def self.reset_local(bug, rules)
    Alert.local_alerts.joins(:attachment).where(attachments: { bug: bug }).where(rule: rules).delete_all
  end
end
