class NotesController < ApplicationController
  load_and_authorize_resource

  def create
    if Note::TEMPLATE_RESEARCH == params[:note][:comment]
      render json: 'Unchanged content', status: 422
      return
    end
    if params[:is_research_notes].present?
      @note = Bug.where("id=?", params[:note][:bugzilla_id]).first
      @note.research_notes = params[:note][:comment]
    else
      if params[:note][:id]
        @note = Note.where("id=?", params[:note][:id]).first
        @note.comment = params[:note][:comment]
      else
        @note = Note.new(note_params.merge(author: current_user.email))
        @note.bug_id ||= params[:note][:bugzilla_id]
      end
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
          :note_id => params[:note][:id],
          :id => params[:note][:bugzilla_id],
          :comment => params[:note][:comment],
          :note_type => params[:note][:note_type],
          :author => current_user.email,
          :is_private => params[:note][:is_private],
          :is_markdown => params[:note][:is_markdown],
          :minor_update => params[:note][:minor_update]
      }.reject() { |k, v| v.nil? }
      xmlrpc = Bugzilla::Bug.new(bugzilla_session)
      if Note.process_note(options, xmlrpc)
        render json: "Note Published!", status: 200
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

