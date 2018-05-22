class CreateDisputeRuleHits < ActiveRecord::Migration[5.1]
  def change
    create_table :dispute_rule_hits do |t|
      t.integer         :rule_number
      t.string          :mnemonic
      t.string          :name
      t.string          :rule_type
      t.integer         :dispute_entry_id
      t.timestamps
    end
  end
end
