class RemoveTableSequenceFromAmpNamingConventions < ActiveRecord::Migration[5.2]
  def change
    remove_index :amp_naming_conventions, :table_sequence
    remove_column :amp_naming_conventions, :table_sequence
  end
end
