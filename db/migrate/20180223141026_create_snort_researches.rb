class CreateSnortResearches < ActiveRecord::Migration[5.1]
  def change
    create_table :snort_researches do |t|
      t.integer     :bug_id
      t.integer     :snort_research_to_research_bug_id
      t.timestamps
    end
  end
end
