class CreateFileRefs < ActiveRecord::Migration[5.1]
  def change
    create_table :file_refs do |t|
      t.timestamps
      t.string :file_name
      t.text :location
      t.string :file_type_name
      t.integer :source_file_ref_id
    end
  end
end
