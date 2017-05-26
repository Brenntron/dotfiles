module NotesHelper

  def get_bug_url
    "https://#{Rails.application.config.bugzilla_host}/show_bug.cgi?id=#{@bug.id}"
  end

  def get_last_notes type, author
    @bug.notes.unpublished.where("note_type=? and author=?", type, author).reverse_chron.first if @bug.notes.any?
  end

  def get_username(email)
    user = User.find_by email: email
    user.nil? ? email : user.cvs_username
  end

  def get_ref_url(ref, name)
    rt = ReferenceType.find_by name: name
    rt.url.gsub('DATA', ref.reference_data)
  end

end