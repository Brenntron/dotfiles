class Escalations::Webcat::ComplaintEntriesController < Escalations::WebcatController

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: ComplaintEntryDatatable.new(params,
                                                 initialize_params,
                                                 user: current_user)
      end
    end
  end

  def show
    @complaint_entry = ComplaintEntry.find(params[:id])
    @complaint = @complaint_entry.complaint
    @lookup = @complaint_entry.domain.presence || @complaint_entry.ip_address
    @org_name = if @complaint.customer.nil?
                  'Guest'
                else
                  @complaint.customer_org
                end
    @source = @complaint.ticket_source
    @submitted_ip_uri = @complaint_entry.uri || @complaint_entry.ip_address
    @input_ip_uri = if ['COMPLETED', 'PENDING', 'REOPENED'].include?(@complaint_entry.status) && !@complaint_entry.uri_as_categorized&.empty?
                      @complaint_entry.uri_as_categorized.presence || @complaint_entry.ip_address
                    elsif ['COMPLETED', 'PENDING', 'REOPENED'].include?(@complaint_entry.status) || !@complaint_entry.domain.empty?
                      @complaint_entry.domain || @complaint_entry.ip_address
                    else
                      @complaint_entry.uri || @complaint_entry.ip_address
                    end
    @input_domain = if @complaint_entry.uri_as_categorized? && @complaint_entry.uri_as_categorized != @complaint_entry.domain
                      @complaint_entry.domain.presence || @complaint_entry.ip_address
                    end
    @tags = @complaint.complaint_tags.map(&:name)
    @wbrs_score = @complaint_entry.wbrs_score.nil? ? 0 : @complaint_entry.wbrs_score.round(1)
    @webcat_users = User.joins(:roles).where('roles.role like "%webcat%"').distinct.order(:display_name)
  end

  def update
  end

  def serve_image
    complaint_entry = ComplaintEntry.find(params[:complaint_entry_id])
    data = complaint_entry.complaint_entry_screenshot&.screenshot     #<—this should return a binary blob
    if data
      send_data data, type: 'image/jpeg'
    else
      file_data = File.open("app/assets/images/removed_screenshot.jpg").read()
      send_data file_data, type: 'image/jpeg'
    end
  end


  private

  def index_params
    params.fetch(:dispute, {}).permit(:customer_name, :customer_email, :customer_company_name,
                                      :status, :resolution, :subject,
                                      :value)
  end

  def datatables_search_params
    params.fetch(:search, {value: ''}).permit(:value)
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
