class CreateFileReps < ActiveRecord::Migration[5.2]
  def change
    create_table :file_reps do |t|
      t.timestamps
      t.string :file_rep_name
      t.text :sha256_checksum
      t.string :email
    end
  end
end
