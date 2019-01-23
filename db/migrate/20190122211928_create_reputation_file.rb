class CreateReputationFile < ActiveRecord::Migration[5.2]
  def change
    create_table :reputation_files do |t|
      t.integer :bugzilla_attachment_id
      t.string :sha256, unique: true
      t.string :file_path
      t.string :file_name
    end
  end
end

