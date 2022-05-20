class Escalations::Sdr::DisputesController < ApplicationController
  # load_and_authorize_resource class: 'Dispute'

  before_action :require_login

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: SdrDisputeDatatable.new(params, initialize_params, user: current_user)
      end
    end
  end

  def show
    @dispute = SenderDomainReputationDispute.where(id: params[:id]).first
    @beaker_info = @dispute.beaker_info
    @versioned_items = @dispute.compose_versioned_items
  end

  def all_attachments
    dispute = SenderDomainReputationDispute.find(params[:dispute_id])
    if dispute.sender_domain_reputation_dispute_attachments.any?
      zip_directory = Dir.mktmpdir
      bug_proxy = bugzilla_rest_session.build_bug(id: dispute.id)
      bug_attachments = bug_proxy.attachments

      zip_filename = "sdr_export-#{Time.now.utc.iso8601}.zip"
      temp_file = Tempfile.new(zip_filename)

      file_attachments = []

      bug_attachments.each do |bug_attachment|
        sdr_attach = SenderDomainReputationDisputeAttachment.find(bug_attachment.id)
        File.open("#{zip_directory}/#{sdr_attach.file_name}", "w") { |f| f.write bug_attachment.file_contents}
        file_attachments << sdr_attach.file_name
      end


      begin
        Zip::OutputStream.open(temp_file) { |zos| }

        #Add files to the zip file as usual
        Zip::File.open(temp_file.path, Zip::File::CREATE) do |zipfile|
          file_attachments.each do |file_attachment|
            zipfile.add(file_attachment, File.join(zip_directory, file_attachment))
          end
        end

        #Read the binary data from the file
        zip_data = File.read(temp_file.path)

        #Send the data to the browser as an attachment
        #We do not send the file directly because it will
        #get deleted before rails actually starts sending it
        send_data(zip_data, :type => 'application/zip', :filename => zip_filename)
      ensure
        #Close and delete the temp file
        temp_file.close
        temp_file.unlink

        #delete all the generated temp files
        file_attachments.each do |file_attachment|
          File.delete(File.join(zip_directory, file_attachment))
        end
      end
    end
  end

  private

    def datatables_search_params
      params.require(:search).permit(:value)
    end

    def robust_search_params
      params.permit(:search, :search_type, :search_name)
    end

    def search_conditions
      params.has_key?('search_conditions') ? params.require('search_conditions').permit! : nil
    end

    def initialize_params
      robust_search_params.merge(datatables_search_params).merge('search_conditions' => search_conditions)
    end
end
