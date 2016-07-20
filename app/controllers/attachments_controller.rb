class AttachmentsController < ApplicationController

  def create
    file_content = params[:attachment][:file_data].tempfile.read
    options = {
        :ids => params[:bug_id],
        :data => XMLRPC::Base64.new(file_content),
        :file_name => params[:attachment][:file_data].original_filename,
        :summary => params[:attachment][:summary],
        :content_type => params[:attachment][:file_data].content_type,
        :comment => params[:attachment][:comment],
        :is_patch => params[:attachment][:is_patch],
        :is_private => params[:attachment][:is_private],
        :minor_update => params[:attachment][:minor_update]
    }.reject() { |k, v| v.nil? } #remove any nil values in the hash(bugzilla doesnt like them)
    new_attachment = Bugzilla::Bug.new(bugzilla_session).add_attachment(options) #the bugzilla session is where we authenticate
    new_attachment_id = new_attachment["ids"][0]
    if new_attachment_id
      new_attach = Attachment.create(
          :size => params[:attachment][:file_data].tempfile.size,
          :bugzilla_attachment_id => options[:ids],
          :file_name => options[:file_name],
          :summary => options[:summary],
          :content_type => options[:type],
          :direct_upload_url => "https://"+ Rails.configuration.bugzilla_host + "/attachment.cgi?id=",
          :creator => current_user.email,
          :is_private => options[:is_private],
          :is_obsolete => false,
          :minor_update => options[:minor_update]
      )
      Bug.where(id: options[:ids]).first.attachments << new_attach
      render json: new_attach
    else
      render json: 'failed'
    end
  end

  private

  def attachment_params
    params.require(:attachment).permit(:summary, :file_name, :bug_id, :bugzilla_attachment_id)
  end

end