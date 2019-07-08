class Escalations::Webcat::ComplaintEntriesController < Escalations::WebcatController

  def index
    respond_to do |format|
      format.html
      format.json do
        byebug
        render json: ComplaintEntryDatatable.new(params,
                                                 initialize_params,
                                                 user: current_user)
      end
    end
  end

  def show
    @complaint_entry = ComplaintEntry.find(params[:id])
  end

  def update
  end

  def serve_image
    complaint_entry = ComplaintEntry.find(params[:complaint_entry_id])
    data = complaint_entry.complaint_entry_screenshot&.screenshot     #<—this should return a binary blob
    if data
      send_data data, type: 'image/jpeg'
    else
      send_data "", type: 'image/jpeg'
    end
  end


  private

  def index_params
    params.fetch(:dispute, {}).permit(:customer_name, :customer_email, :customer_company_name,
                                      :status, :resolution, :subject,
                                      :value)
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
