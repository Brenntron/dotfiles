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
    @ce_rpt_params = ce_rpt_params
    @report = WebcatReport::ComplaintEntryReport.new(date_from: ce_rpt_params['date_from'],
                                                     date_to: ce_rpt_params['date_to'],
                                                     customer_name: ce_rpt_params['customer_name'])
  end

  def export_complaint_entry
    @ce_rpt_params = ce_rpt_params
    @report = WebcatReport::ComplaintEntryReport.new(date_from: ce_rpt_params['date_from'],
                                                     date_to: ce_rpt_params['date_to'],
                                                     customer_name: ce_rpt_params['customer_name'])

    contents = CSV.generate do |csv|
      csv << [ 'Customer Name', 'URL', 'Engineer', 'Resolution', 'Final Category', 'Suggested Category', 'Created' ]
      @report.each_entry do |entry|
        csv << [ entry.customer_name, entry.uri, entry.user_display_name, entry.resolution,
                 entry.category, entry.suggested_disposition, entry.created_at ]
      end
    end
    send_data contents
  end

  private

  def ce_rpt_params
    params.require(:report).permit(:date_from, :date_to, :customer_name)
  end
end
