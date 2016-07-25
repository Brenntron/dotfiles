class NotesController < ApplicationController
  
  def create
    if params[:note][:id]
      @note = Note.where("id=?", params[:note][:id]).first
      @note.comment = params[:note][:comment]
    else
      @note = Note.new(
          :comment => params[:note][:comment],
          :author => current_user.email,
          :note_type => params[:note][:note_type],
          :bug_id => params[:note][:bugzilla_id]
      )
    end
    if @note.save
      render json: @note
    else
      render json: "Error. Could not save the note", status: 422
    end
  end
  
  def publish_to_bugzilla
    begin
      options = {
          :id => params[:note][:bugzilla_id],
          :comment => params[:note][:comment],
          :note_type => params[:note][:note_type],
          :author => current_user.email,
          :is_private => params[:note][:is_private],
          :is_markdown => params[:note][:is_markdown],
          :minor_update => params[:note][:minor_update]
      }.reject() { |k, v| v.nil? }
      new_note = Bugzilla::Bug.new(bugzilla_session).add_comment(options)
      if params[:note][:id]
        @note = Note.where("id=?",params[:note][:id]).first
      else
        @note = Note.create(id: new_note['id'])
      end
      @bug = Bug.find params[:note][:bugzilla_id]
      if @note.update(:id => new_note['id'],:comment => params[:note][:comment], :notes_bugzilla_id => new_note['id'])
        render json: {bug: @bug.as_json, note: @note.as_json}
      else
        render json: "Published to bugzilla but not updated in local db", status: 422
      end
    rescue => e
      render json: "Error. Could not publish to bugzilla", status: 422
    end

  end
  
end