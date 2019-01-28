class RemoveAmpFalsePositiveFiles < ActiveRecord::Migration[5.2]
  def up
    drop_table :amp_false_positive_files
  end
  def down
    create_table :amp_false_positive_files
  end
end