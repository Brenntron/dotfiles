class CreateEscalations < ActiveRecord::Migration[5.1]
  def change
    create_table :escalations do |t|
      t.integer :snort_research_escalation_bug_id
      t.integer :snort_escalation_research_bug_id
      t.timestamps
    end
  end
end
