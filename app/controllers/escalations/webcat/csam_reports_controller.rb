class Escalations::Webcat::CsamReportsController < Escalations::WebcatController
  before_action { authorize!(:read, Complaint) }

  def index
    binding.pry

    @reports = AbuseRecord.all

    respond_to do |format|
      binding.pry
      format.html
      format.json do
        render json: AbuseRecordDatatable.new(params, current_user)
      end
    end
  end









end