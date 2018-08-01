class Escalations::WebcatController < ApplicationController
  before_action :require_login
  before_action :dashboard_metrics

  def dashboard_metrics
    @ti_comps = Complaint.from_ti.count
    @ti_comp_entries = Complaint.from_ti.map{ |c| c.complaint_entries.size }.inject(0){ |sum,item| sum + item }
    @int_comps = Complaint.from_int.count
    @int_comp_entries = Complaint.from_int.map{ |c| c.complaint_entries.size }.inject(0){ |sum,item| sum + item }
    @wbnp = "-"

    @active_comp = Complaint.active_count
    @completed_comp = Complaint.completed_count
    @new_comp = Complaint.new_count
    @overdue_comp = Complaint.overdue_count

    @assigned = ComplaintEntry.assigned_count
    @pending = ComplaintEntry.pending_count
    @new = ComplaintEntry.new_count
    @overdue = ComplaintEntry.overdue_count

  end
end