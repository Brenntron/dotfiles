class Escalations::Webcat::CsamReportsController < Escalations::WebcatController
  before_action { authorize!(:read, Complaint) }

  def index
  end









end