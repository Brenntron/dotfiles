class UniquenessAmpNaming < ActiveRecord::Migration[5.2]
  def change
    add_index :amp_naming_conventions, :table_sequence, unique: true
  end
end
