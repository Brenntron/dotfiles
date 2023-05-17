class Escalations::Sdr::DisputesController < ApplicationController
  # load_and_authorize_resource class: 'Dispute'

  before_action :require_login

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: SdrDisputeDatatable.new(params, initialize_params, user: current_user)
      end
      format.xlsx do
        workbook = SenderDomainReputationDispute.export_xlsx(params['data_json'], current_user: current_user)
        send_data workbook.stream.string, filename: "sdr_search_#{Time.now}.xlsx", disposition: 'attachment'
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

      offset = 0
      file_attachments = []
      bug_attachments.each do |bug_attachment|
        sdr_attach = SenderDomainReputationDisputeAttachment.find(bug_attachment.id)
        split_file_name = sdr_attach.file_name.split('.')
        temp_file_name = "#{split_file_name.first}_#{(Time.now.to_i + offset).to_s}.#{split_file_name.last}"

        # [Upgrading rails from 5.2 to 6.0.1]
        # Previously, the return value of ActionDispatch::Response#content_type did NOT contain the charset part.
        # This behavior has changed to include the previously omitted charset part as well.
        # If you want just the MIME type, please use ActionDispatch::Response#media_type instead.
        enconding = bug_attachment.media_type.eql?("application/pdf") ? 'wb' : 'w'
        File.open("#{zip_directory}/#{temp_file_name}", enconding) { |f| f.write bug_attachment.file_contents }
        file_attachments << temp_file_name
        offset += 1
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

  def resolution_message_templates
    @templates = ResolutionMessageTemplate.for_sdr_disputes
    @customer_footer_exists = ResolutionMessageTemplate.by_sdr_reputation_disputes('Customer Footer').exists?
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
