class CreateS3Urls < ActiveRecord::Migration[5.1]
  def change
    create_table :s3_urls do |t|
      t.timestamps
      t.text :url
      t.string :file_name
      t.string :file_type_name
    end
  end
end
