class Escalations::Webcat::CsamReportsController < Escalations::WebcatController
  before_action { authorize!(:read, Complaint) }

  def index

    @reports = AbuseRecord.all

    respond_to do |format|
      format.html
      format.json do
        render json: AbuseRecordDatatable.new(params, current_user)
      end
    end
  end









end