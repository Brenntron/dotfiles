class Escalations::Webcat::CsamReportsController < Escalations::WebcatController
  before_action { authorize!(:read, Complaint) }

  def index

    respond_to do |format|
      format.html
      format.json do
        render json: AbuseRecordDatatable.new(params, user: current_user)
      end
    end
  end









end