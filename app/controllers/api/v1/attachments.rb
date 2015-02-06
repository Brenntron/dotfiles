module API
  module V1
    class Attachments < Grape::API
      include API::V1::Defaults

      resource :attachments do
        desc "get all attachments"
        get "", root: :attachments do
          Attachment.all
        end

        desc "get an attachments"
        params do
          requires :id, type: String, desc: "ID of the attachment"
        end
        get ":id", root: "attachment" do
          Attachment.where(id: permitted_params[:id])
        end

        #create an attachment

        #create multiple attachemnts

        #edit an attachment

        #update an attachement

        #delete an attachment



      end
    end
  end
end