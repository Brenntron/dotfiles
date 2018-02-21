class CreateEscalations < ActiveRecord::Migration[5.1]
  def change
    create_table :escalations do |t|
      t.integer :snort_research_bug_id
      t.integer :snort_escalation_bug_id
      #t.integer :research_bug_id
      #t.integer :escalation_bug_id
      #t.string  :type
      t.timestamps
    end
  end
end


#class CreateEscalations < ActiveRecord::Migration[5.1]
#  def change
#    create_table :escalations do |t|
      #t.integer :snort_research_bug_id
      #t.integer :snort_escalation_bug_id
      #t.integer :research_bug_id
      #t.integer :escalation_bug_id
#      t.integer :escalation_escalatable_id
#      t.string  :escalation_escalatable_type
#      t.integer :research_escalatable_id
#      t.string  :research_escalatable_type
#      t.timestamps
#    end
#  end
#end
