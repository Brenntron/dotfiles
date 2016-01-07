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
        desc "Create an attachment"
        params do
          requires :attachment, type: Hash do
            requires :bugzilla_attachment_id, type: String, desc: "id of the bug you want to attach to"
            requires :file_data, type: Hash
            requires :summary, type: String, desc: "what is this attachment"
            optional :comment, type: String, desc: "a comment to add along with this attachment"
            optional :is_patch, type: Boolean, desc: "true if bugzilla should treat this as a patch"
            optional :is_private, type: Boolean, desc: "true if the attachment should be private"
            optional :minor_update, type: Boolean, desc: "if true emails wont be sent to users who dont want minor updates"
          end
        end
        post "", root: "attachment" do
          file_content = permitted_params[:attachment][:file_data][:tempfile].read
          options = {
              :ids => permitted_params[:attachment][:bugzilla_attachment_id],
              :data => XMLRPC::Base64.new(file_content),
              :file_name => permitted_params[:attachment][:file_data][:filename],
              :summary => permitted_params[:attachment][:summary],
              :content_type => permitted_params[:attachment][:file_data][:type],
              :comment => permitted_params[:attachment][:comment],
              :is_patch => permitted_params[:attachment][:is_patch],
              :is_private => permitted_params[:attachment][:is_private],
              :minor_update => permitted_params[:attachment][:minor_update]
          }.reject() { |k, v| v.nil? } #remove any nil values in the hash(bugzilla doesnt like them)
          new_attachment = Bugzilla::Bug.new(bugzilla_session).add_attachment(options) #the bugzilla session is where we authenticate
          new_attachment_id = new_attachment["ids"][0]
          if new_attachment_id
            new_attach = Attachment.create(
                # :id => new_attachment_id,
                :size => permitted_params[:attachment][:file_data][:tempfile].size,
                :bugzilla_attachment_id => options[:ids],
                :file_name => options[:file_name],
                :summary => options[:summary],
                :content_type => options[:type],
                :direct_upload_url => "https://"+ Rails.configuration.bugzilla_host + "/attachment.cgi?id=" + new_attachment_id.to_s,
                :creator => current_user.email,
                :is_private => options[:is_private],
                :is_obsolete => false,
                :minor_update => options[:minor_update]
            )
            Bug.where(id: options[:ids]).first.attachments << new_attach
          else
            return false
          end
          new_attach
        end

        #create multiple attachemnts

        #update an attachment
        # desc "update an attachment"
        # params do
        #   requires :ids, type: String, desc: "id of the attachment want to update"
        #   optional :attachment, type: Hash do
        #     optional :bugzilla_attachment_id, type: String, desc: "id of the bug you want to attach to"
        #     optional :summary, type: String, desc: "what is this attachment"
        #     optional :comment, type: String, desc: "a comment to add along with this attachment"
        #     optional :is_patch, type: Boolean, desc: "true if bugzilla should treat this as a patch"
        #     optional :is_private, type: Boolean, desc: "true if the attachment should be private"
        #     optional :is_obsolete, type: Boolean, desc: "true if the attachment should be deleted"
        #     optional :minor_update, type: Boolean, desc: "if true emails wont be sent to users who dont want minor updates"
        #   end
        # end
        # route_param :ids do
        #   put do
        #     options = {
        #         :ids =>[permitted_params[:ids].to_i],
        #         :file_name => permitted_params[:attachment][:file_name],
        #         :summary => permitted_params[:attachment][:summary],
        #         :content_type => permitted_params[:attachment][:content_type],
        #         :is_obsolete => permitted_params[:attachment][:is_obsolete],
        #         :is_private => permitted_params[:attachment][:is_private],
        #         :is_patch => permitted_params[:attachment][:is_patch]
        #     }
        #     options.reject! { |k, v| v.nil? }
        #     update_params = permitted_params[:attachment].reject { |k, v| v.nil? }
        #     # updated_attachment = Bugzilla::Bug.new(bugzilla_session).update(options)
        #
        #     if updated_attachment['attachments'].empty?
        #       #nothing came back so the update must have failed
        #       return {error: 'attachment not updated'}
        #     else
        #       if Attachment.update(permitted_params[:ids], update_params)
        #         render json: Attachment.where(id: permitted_params[:ids]), status: 200
        #       else
        #         render json: bug.errors, status: :unprocessable_entity
        #       end
        #     end
        #   end
        # end


      end
    end
  end
end