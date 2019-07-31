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

  def rules
  end

  def reports
  end

  def show_multiple
    ids = params["selected_ids"]&.split(',') || nil
    @complaints = Complaint.where(id:ids)
  end
  def advanced_search

  end

  def named_search
  end

  def standard_search
  end

  def contains_search
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
end
