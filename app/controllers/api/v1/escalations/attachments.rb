module API
  module V1
    module Escalations
      class Attachments < Grape::API
        include API::V1::Defaults

        resource "escalations/attachments" do
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
          desc "Create an attachment"
          params do
            requires :attachment, type: Hash do
              requires :bugzilla_attachment_id, type: String, desc: "id of the attachment located in bugzilla"
              requires :file_data, type: Hash
              requires :summary, type: String, desc: "what is this attachment"
              optional :comment, type: String, desc: "a comment to add along with this attachment"
              optional :is_patch, type: Boolean, desc: "true if bugzilla should treat this as a patch"
              optional :is_private, type: Boolean, desc: "true if the attachment should be private"
              optional :minor_update, type: Boolean, desc: "if true emails wont be sent to users who dont want minor updates"
            end
          end
          post "" , root: :attachments do
            authorize! :create, Attachment
            bug = Bug.where(id: permitted_params[:attachment][:bugzilla_attachment_id]).first

            bug.add_escalation_attachment_action(bugzilla_session,
                                      permitted_params[:attachment][:file_data][:tempfile],
                                      user: current_user,
                                      filename: permitted_params[:attachment][:file_data][:filename],
                                      content_type: permitted_params[:attachment][:file_data][:type],
                                      comment: permitted_params[:attachment][:comment],
                                      is_patch: permitted_params[:attachment][:is_patch],
                                      is_private: permitted_params[:attachment][:is_private],
                                      minor_update: permitted_params[:attachment][:minor_update])

          end

        end
      end
    end
  end
end