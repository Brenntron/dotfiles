class CreateRuleDocs < ActiveRecord::Migration[4.2]
  def change
    create_table :rule_docs do |t|
      t.integer :rule_id, index: true
      t.text    :summary
      t.text    :impact
      t.text    :details
      t.text    :affected_sys
      t.text    :attack_scenarios
      t.text    :ease_of_attack
      t.text    :false_positives
      t.text    :false_negatives
      t.text    :corrective_action
      t.text    :contributors

      t.timestamps
    end
  end
end

