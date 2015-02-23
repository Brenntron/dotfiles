class CreateNotes < ActiveRecord::Migration
  def change
    create_table :notes do |t|
      t.text  "content"
      t.string "note_type"
      t.string "author"
      t.timestamps
    end
    add_reference :notes, :bug, index: true
  end
end
