class Escalations::Webcat::ClustersController < Escalations::WebcatController
  before_action { authorize!(:read, Complaint) }

  def index
  end

  def rules
    puts params
  end

  private
  def research_params
    params.fetch(:search, {}).permit(:uri, :scope)
  end
end