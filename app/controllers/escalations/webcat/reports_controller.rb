class Escalations::Webcat::ReportsController < Escalations::WebcatController
  def index

  end

  def resolution
    @report = WebcatReport::ResolutionReport.new(date_from: params['date_from'],
                                                 date_to: params['date_to'])
  end
end
