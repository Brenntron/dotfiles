module Escalations::Webrep::Disputes::ResolutionReportHelper
  def age_report_path(options = {})
    resolution_age_report_escalations_webrep_disputes_path(options.select{|kk, vv| vv.present?})
  end
end
