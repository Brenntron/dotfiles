class Escalations::Webcat::RulesController < Escalations::WebcatController
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

  def copycat_tool
    puts 'Copycat'
  end
end
