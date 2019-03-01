class CreateFileReps < ActiveRecord::Migration[5.2]
  def change
    create_table :file_reps do |t|
      t.timestamps
      t.text :sha256
      t.string :email
    end
  end
end
