module API
  module V1
    class Notes < Grape::API
      include API::V1::Defaults

      resource :notes do
        desc "Return all notes"
        get "", root: :notes do
          Note.all
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
      end
    end
  end
end


