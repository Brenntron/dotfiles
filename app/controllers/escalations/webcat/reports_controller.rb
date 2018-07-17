class Escalations::Webcat::ReportsController < Escalations::WebcatController
  before_action { authorize!(:read, Complaint) }

  def index
  end
end
