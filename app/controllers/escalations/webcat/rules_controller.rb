class Escalations::Webcat::RulesController < Escalations::WebcatController
  before_action { authorize!(:read, Complaint) }

  def index
  end
end
