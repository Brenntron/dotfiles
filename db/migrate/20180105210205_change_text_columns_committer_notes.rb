class ChangeTextColumnsCommitterNotes < ActiveRecord::Migration[5.1]
  def change
    change_column :bugs, :committer_notes, :text
  end
end
