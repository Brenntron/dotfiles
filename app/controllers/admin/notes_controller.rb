class Admin::NotesController < Admin::HomeController
  load_and_authorize_resource class: 'Admin'

  def index
    respond_to do |format|
      format.html
    end

  end
  def edit
    @note = Note.find(params[:id])
  end

  def update
    @note = Note.find(params[:id])
    @note.update(note_params)
    if @note.save
      flash[:notice] = "Note: #{@note.sid} updated successfully."
    else
      flash[:alert] = "Unable to update Note: #{@note.sid}."
    end
    redirect_to admin_notes_path
  end

  # DELETE /roles/1
  # DELETE /roles/1.json
  def destroy
    @note = Note.find(params[:id])
    @note.destroy
    respond_to do |format|
      format.html { redirect_to admin_notes_path, notice: 'note was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def related
    @note = Note.where(id: params[:id]).first || Note.new
  end

  private

  def note_params
    params.require(:note).permit(:comment, :note_type, :author, :notes_bugzilla_id,:bug_id)
  end
end