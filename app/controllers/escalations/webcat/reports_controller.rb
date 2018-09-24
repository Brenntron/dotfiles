class Escalations::Webcat::ReportsController < Escalations::WebcatController
  before_action { authorize!(:read, Complaint) }

  def index
  end

  def resolution
    @report = WebcatReport::ResolutionReport.new(date_from: params['report']['date_from'],
                                                 date_to: params['report']['date_to'])
  end

  def export_resolution
    @report = WebcatReport::ResolutionReport.new(date_from: params['date_from'],
                                                 date_to: params['date_to'])

    contents = CSV.generate do |csv|
      csv << [ '', 'Fixed Complaints', 'Invalid Complaints', 'Unchanged Complaints', 'Duplicate Complaints',
               'Eng Ave', 'Eng Max', 'Dept Ave', 'Dept Max' ]
      @report.each_engineer do |counts|
        csv << [ counts.username, counts.fixed, counts.invalid, counts.unchanged, counts.duplicate,
                 ApplicationRecord.humanize_secs(counts.eng_avg), ApplicationRecord.humanize_secs(counts.eng_max),
                 ApplicationRecord.humanize_secs(counts.dept_avg), ApplicationRecord.humanize_secs(counts.dept_max) ]
      end
    end
    send_data contents
  end

  def complaint_entry
    @report = WebcatReport::ComplaintEntryReport.new(date_from: params['report']['date_from'],
                                                     date_to: params['report']['date_to'])
  end
end
