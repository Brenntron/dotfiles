class Escalations::Webcat::ClustersController < Escalations::WebcatController
  before_action { authorize!(:read, Complaint) }

  def index
  end
end
