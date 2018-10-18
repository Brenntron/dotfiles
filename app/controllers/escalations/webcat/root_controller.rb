class Escalations::Webcat::RootController < Escalations::WebcatController
  def index
    redirect_to escalations_webcat_complaints_path
  end
end
