class RemoveAmpFalsePositives < ActiveRecord::Migration[5.2]
  def up
    drop_table :amp_false_positives
  end
  def down
    create_table :amp_false_positives
  end
end
