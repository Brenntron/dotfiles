class ChangeRlScoreToInteger < ActiveRecord::Migration[5.2]
  def change
    change_column :file_reputation_disputes, :reversing_labs_score, :integer
  end
end
