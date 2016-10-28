class DropRulesColumns < ActiveRecord::Migration
  def change
    remove_column :rules, :attachment_id, :integer
    remove_column :rules, :reference_id,  :integer
    remove_column :rules, :bug_id,        :integer
  end
end
