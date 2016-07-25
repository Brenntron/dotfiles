module NotesHelper

  def get_notes_saved type, author
    @bug.notes.where("note_type=? and author=? and notes_bugzilla_id is ?", type, author, nil).last if @bug.notes != []
  end

  def get_username(email)
    user = User.find_by email: email
    user.nil? ? email : user.cvs_username
  end

end