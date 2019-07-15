class ChangeDescriptionToBeTextInFileReputationDisputes < ActiveRecord::Migration[5.2]
  def change
    change_column :file_reputation_disputes, :description, :text
  end
end
