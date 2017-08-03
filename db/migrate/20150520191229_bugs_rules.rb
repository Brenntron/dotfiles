class BugsRules < ActiveRecord::Migration[4.2]
  def change
    create_table :bugs_rules, id: false do |t|
      t.integer :bug_id
      t.integer :rule_id
    end
    reversible do |dir|
      dir.up do
        # add a primary key constraint
        execute <<-SQL
          ALTER TABLE bugs_rules ADD PRIMARY KEY (bug_id,rule_id);
        SQL
      end
      dir.down do
        execute <<-SQL
          ALTER TABLE bugs_rules DROP PRIMARY KEY;
        SQL
      end
    end

  end
end
