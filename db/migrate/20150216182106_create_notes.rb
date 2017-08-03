class CreateNotes < ActiveRecord::Migration[4.2]
  def change
    create_table :notes do |t|
      t.text  :comment
      t.string :note_type
      t.string :author
      t.integer :notes_bugzilla_id, default: nil
      t.timestamps
    end
    add_reference :notes, :bug, index: true
  end
end
