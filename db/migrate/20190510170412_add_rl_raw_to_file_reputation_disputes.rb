class AddRlRawToFileReputationDisputes < ActiveRecord::Migration[5.2]
  def change
    add_column :file_reputation_disputes, :reversing_labs_raw, :text
  end
end
