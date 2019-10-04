class AddSequenceToAmpNamingConventions < ActiveRecord::Migration[5.2]
  def change
    add_column :amp_naming_conventions, :table_sequence, :integer
  end
end
