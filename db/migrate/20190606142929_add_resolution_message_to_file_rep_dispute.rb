class AddResolutionMessageToFileRepDispute < ActiveRecord::Migration[5.2]
  def change
    add_column :file_reputation_disputes, :resolution_comment, :text
  end
end
