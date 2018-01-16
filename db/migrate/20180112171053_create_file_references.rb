class CreateFileReferences < ActiveRecord::Migration[5.1]
  def change
    create_table :file_references do |t|
      t.timestamps
      t.string :type
      t.string :file_name
      t.text :location
      t.string :file_type_name
      t.string :source
    end
  end
end
