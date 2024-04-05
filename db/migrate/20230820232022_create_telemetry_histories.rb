class CreateTelemetryHistories < ActiveRecord::Migration[6.1]
  def change
    create_table :telemetry_histories do |t|
      t.float        :wbrs_score
      t.float        :sbrs_score
      t.float        :multi_ip_score
      t.text         :rule_hits
      t.text         :multi_rule_hits
      t.text         :threat_categories
      t.text         :multi_threat_categories
      t.integer      :dispute_entry_id
      t.boolean      :original_snapshot
      t.timestamps
    end
  end
end
