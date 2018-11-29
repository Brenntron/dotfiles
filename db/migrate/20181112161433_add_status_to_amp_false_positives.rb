class AddStatusToAmpFalsePositives < ActiveRecord::Migration[5.1]
  def change
    add_column :amp_false_positives, :status, :string
  end
end
