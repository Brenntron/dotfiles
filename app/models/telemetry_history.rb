class TelemetryHistory < ApplicationRecord

  belongs_to :dispute_entry

  def self.initialize_dispute_entry_snapshot(packet, dispute_entry_id, original = false)

    th = TelemetryHistory.new
    th.wbrs_score = packet[:wbrs_score] if packet[:wbrs_score].present?
    th.sbrs_score = packet[:sbrs_score] if packet[:sbrs_score].present?
    th.multi_ip_score = packet[:multi_ip_score] if packet[:multi_ip_score].present?
    th.rule_hits = packet[:rule_hits] if packet[:rule_hits].present?
    th.dispute_entry_id = dispute_entry_id
    th.multi_rule_hits = packet[:multi_rule_hits] if packet[:multi_rule_hits].present?
    th.multi_threat_categories = packet[:multi_threat_categories] if packet[:multi_threat_categories].present?
    th.threat_categories = packet[:threat_categories] if packet[:threat_categories].present?
    th.original_snapshot = original
    th.save

    th

  end

  def self.save_dispute_entry_snapshot(packet, dispute_entry_id, original = false)

    th = TelemetryHistory.new
    th.wbrs_score = packet[:wbrs_score] if packet[:wbrs_score].present?
    th.sbrs_score = packet[:sbrs_score] if packet[:sbrs_score].present?
    th.multi_ip_score = packet[:multi_ip_score] if packet[:multi_ip_score].present?
    th.rule_hits = packet[:rule_hits] if packet[:rule_hits].present?
    th.dispute_entry_id = dispute_entry_id
    th.multi_rule_hits = packet[:multi_rule_hits] if packet[:multi_rule_hits].present?
    th.multi_threat_categories = packet[:multi_threat_categories] if packet[:multi_threat_categories].present?
    th.threat_categories = packet[:threat_categories] if packet[:threat_categories].present?
    th.original_snapshot = original
    th.save

    th

  end


end
