class Escalations::Webcat::ComplaintEntriesController < Escalations::WebcatController



  def index
    respond_to do |format|
      format.html
      format.json { render json: ComplaintEntryDatatable.new(view_context) }
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
end
