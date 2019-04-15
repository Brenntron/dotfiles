class AddColumnsToFileRep < ActiveRecord::Migration[5.2]
  def change
    add_column :file_reputation_disputes, :case_closed_at, :datetime
  end
end
