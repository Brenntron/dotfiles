class RemoveTableSequenceFromAmpNamingConventions < ActiveRecord::Migration[5.2]
  def change
    # commenting out because we should wait until 2024 to remove these columns for rollback purposes
    # remove_index :amp_naming_conventions, :table_sequence
    # remove_column :amp_naming_conventions, :table_sequence
  end
end
