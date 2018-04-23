class CreateDisputeRules < ActiveRecord::Migration[5.1]
  def change
    create_table :dispute_rules do |t|
      t.string        :name
      t.string        :mnemonic
      t.text          :description
      t.string        :rule_type
      t.integer       :rule_number
      t.timestamps
    end
  end
end
