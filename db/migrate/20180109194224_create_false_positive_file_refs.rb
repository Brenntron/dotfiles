class CreateFalsePositiveFileRefs < ActiveRecord::Migration[5.1]
  def change
    create_table :false_positive_file_refs do |t|
      t.timestamps
      t.integer :false_positive_id
      t.string :file_ref_type
      t.integer :file_ref_id
    end
  end
end
