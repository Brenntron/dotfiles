class AutoResolveColumns < ActiveRecord::Migration[6.1]
  def up
    add_column :dispute_entries, :claim, :string
    add_column :dispute_entries, :retries, :integer, :default => 0

  end

  def down
    remove_column :dispute_entries, :claim, :string
    remove_column :dispute_entries, :retries, :integer
  end
end
