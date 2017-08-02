class NotesController < ApplicationController
  load_and_authorize_resource

  def create
    if Note::TEMPLATE_RESEARCH == params[:note][:comment]
      render json: 'Unchanged content', status: 422
      return
    end
    if params[:note][:id]
      @note = Note.where("id=?", params[:note][:id]).first
      @note.comment = params[:note][:comment]
    else
      @note = Note.new(note_params.merge(author: current_user.email))
      @note.bug_id ||= params[:note][:bugzilla_id]
    end
    if @note.save
      render json: @note
    else
      render json: @note.errors.full_messages, status: 422
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
      if params[:note][:id].blank?
        note = Note.create(id: new_note['id'],
                           comment: options[:comment],
                           author: options[:author],
                           note_type: options[:note_type])
      else
        note = Note.where("id=?", params[:note][:id]).first
      end
      bug = Bug.find params[:note][:bugzilla_id]
      bug.notes << note
      if note.update(:id => new_note['id'], :comment => params[:note][:comment], :notes_bugzilla_id => new_note['id'])
        render json: {bug: bug.as_json, note: note.as_json}
      else
        render json: "Published to bugzilla but not updated in local db", status: 422
      end
    rescue => e
      render json: "Error. Could not publish to bugzilla; #{e}", status: 422
    end
  end


  private

  def note_params
    params.require(:note).permit(:comment, :author, :flow, :note_type, :bug_id, :notes_bugzilla_id, :id)
  end

end

