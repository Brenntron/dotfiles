module API
  module V1
    class Attachments < Grape::API
      include API::V1::Defaults

      resource :attachments do
        desc "Return all attachments"
        get "", root: :attachments do
          Attachment.all
        end

        desc "Return a attachments"
        params do
          requires :id, type: String, desc: "ID of the attachment"
        end
        get ":id", root: "attachment" do
          Attachment.where(id: permitted_params[:id])
        end
      end
    end
  end
end