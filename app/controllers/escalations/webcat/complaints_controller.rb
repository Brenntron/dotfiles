class Escalations::Webcat::ComplaintsController < Escalations::WebcatController
  load_and_authorize_resource class: 'Complaint'

  def index
    respond_to do |format|
      format.html
    end
  end

  def show
    @complaint = Complaint.find(params[:id])
  end

  def update
  end

  def clusters
    render layout: "escalations/webcat/clusters"
  end

  def csam_reports
    render layout: "escalations/webcat/csam_reports"
  end

  def show_multiple
    ids = params["selected_ids"]&.split(',') || nil
    @complaints = Complaint.where(id:ids)
  end

  def research
  end

  def advanced_search
  end

  def named_search
  end

  def standard_search
  end

  def contains_search
  end

  def resolution_message_templates
    @templates = ResolutionMessageTemplate.for_webcat_disputes
  end

  private


  def index_params
    params.fetch(:dispute, {}).permit(:customer_name, :customer_email, :customer_company_name,
                                      :status, :resolution, :subject,
                                      :value)
  end
end
