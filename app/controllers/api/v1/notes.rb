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
            requires :content, type: String, desc: "The content of the note."
            requires :author, type: String, desc: "Who wrote the note."
            requires :note_type, type: String, desc: "Is it a Research note or a Committer note?"
            requires :bugzilla_id, type: Integer, desc: "The bug the note pertains to."
          end
        end
        post "", root: "note" do
          Note.create(
            :content => permitted_params[:note][:content],
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


