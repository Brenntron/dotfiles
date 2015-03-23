module API
  module V1
    class Notes < Grape::API
      include API::V1::Defaults

      resource :notes do
        desc "Return all notes"
        get "", root: :notes do
          Note.all
        end

        desc "Create a note"
        params do
          requires :note, type: Hash do
            requires :text, type: String, desc: "The text of the note."
            requires :author, type: String, desc: "Who wrote the note."
            requires :note_type, type: String, desc: "Is it a Research note or a Committer note?"
            requires :bugzilla_id, type: Integer, desc: "The id or alias of the bug to append a comment to."
            optional :is_private, type: Boolean, desc: "If set to true, the comment is private, otherwise it is assumed to be public."
            optional :is_markdown, type: Boolean, desc: "If set to true, the comment has Markdown structures, otherwise it is a normal text."
            optional :minor_update, type: Boolean, desc: "If set to true, this is considered a minor update and no mail is sent to users who do not want minor update emails. If current user is not in the minor_update_group, this parameter is simply ignored."
          end
        end
        post "", root: "note" do
          options = {
            :id => permitted_params[:note][:bugzilla_id],
            :comment => permitted_params[:note][:text],
            :is_private => permitted_params[:note][:is_private],
            :is_markdown => permitted_params[:note][:is_markdown],
            :minor_update => permitted_params[:note][:minor_update]
          }.reject() { |k, v| v.nil? }
          Bugzilla::Bug.new(bugzilla_session).add_comment(options)
          Note.create(
            :text => permitted_params[:note][:text],
            :author => permitted_params[:note][:author],
            :note_type => permitted_params[:note][:note_type],
            :bug_id => permitted_params[:note][:bugzilla_id]
          )
        end

        desc "Return a note"
        params do
          requires :id, type: String, desc: "ID of the note"
        end
        get ":id", root: "note" do
          Note.where(id: permitted_params[:id])
        end

        desc "Return all notes by a specific user"
        params do
          requires :author, type: String, desc: "name of the author"
        end
        get "by_author/:author", root: "note" do
          Note.where("author =? ", permitted_params[:author])
        end

        desc "edit a note"
        params do
          requires :id, type: Integer, desc: "The note's id in the database."
          requires :note, type: Hash do
            requires :text, type: String, desc: "The text of the note."
          end
        end
        put ":id", root: "note" do
          Note.update(permitted_params[:id], permitted_params[:note])
        end


        desc "delete a note"
        params do
          requires :id, type: Integer, desc: "Bugzilla id."
        end
        delete ":id", root: "note" do
          Note.destroy(permitted_params[:id])
        end

      end
    end
  end
end


