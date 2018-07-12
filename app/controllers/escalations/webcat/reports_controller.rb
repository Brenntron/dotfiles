class Escalations::Webcat::ReportsController < Escalations::WebcatController
  def index

  end

  def resolution
    @report = WebcatReport::ResolutionReport.new(date_from: params['date_from'],
                                                 date_to: params['date_to'])
  end

  def export_resolution
    @report = WebcatReport::ResolutionReport.new(date_from: params['date_from'],
                                                 date_to: params['date_to'])

    contents = CSV.generate do |csv|
      csv << [ '', 'Fixed Complaints', 'Invalid Complaints', 'Unchanged Complaints', 'Duplicate Complaints' ]
      @report.each_engineer do |counts|
        csv << [ counts.username, counts.fixed, counts.invalid, counts.unchanged, counts.duplicate ]
      end
    end
    send_data contents
  end
end
