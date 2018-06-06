class Escalations::Webcat::ComplaintsController < Escalations::WebcatController



  def index
    respond_to do |format|
      format.html
      format.json { render json: ComplaintDatatable.new(view_context) }
    end
  end

  def show
    @dispute = Dispute.find(params[:id])
  end

  def update
  end

  def dashboard
  end

  def tickets
  end

  def single
  end

  def advanced_search
    @dispute = Dispute.new
  end

  def named_search
  end

  def standard_search
  end

  def contains_search
  end

  private


  def index_params
    params.fetch(:dispute, {}).permit(:customer_name, :customer_email, :customer_company_name,
                                      :status, :resolution, :subject,
                                      :value)
  end
end
