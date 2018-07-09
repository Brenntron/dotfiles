class AddTopUrlColumnToDisputes < ActiveRecord::Migration[5.1]
  def change
    add_column :dispute_entries, :is_important, :boolean
  end
end
