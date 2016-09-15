class AddNotesBugzillaIdToNotes < ActiveRecord::Migration
  def change
    add_column :notes, :notes_bugzilla_id, :integer, default: nil
    Note.all.each do |note|
      note.update(:notes_bugzilla_id => note.id)
    end
  end
end
