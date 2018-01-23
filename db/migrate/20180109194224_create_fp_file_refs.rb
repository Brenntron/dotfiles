class CreateFpFileRefs < ActiveRecord::Migration[5.1]
  def change
    create_table :fp_file_refs do |t|
      t.timestamps
      t.integer :false_positive_id
      t.integer :file_reference_id
    end
  end
end
