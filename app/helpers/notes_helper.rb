module NotesHelper

  def get_notes_saved type, author
    @bug.notes.where("note_type=? and author=? and notes_bugzilla_id is ?", type, author, nil).last if @bug.notes != []
  end

end