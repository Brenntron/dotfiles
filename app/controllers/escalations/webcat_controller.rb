class Escalations::WebcatController < ApplicationController
  before_action :dashboard_metrics

  private   #because in ruby, private is protected not private

  def dashboard_metrics
    @ti_comp_guest = Complaint.from_ti.by_guest.open_comps.map{ |c| c.complaint_entries.size }.inject(0){ |sum,item| sum + item }
    @ti_comp_cust = Complaint.from_ti.by_cust.open_comps.map{ |c| c.complaint_entries.size }.inject(0){ |sum,item| sum + item }
    @int_comp_entries = Complaint.from_int.open_comps.map{ |c| c.complaint_entries.size }.inject(0){ |sum,item| sum + item }
    @wbnp = Complaint.from_wbnp.open_comps.map{ |c| c.complaint_entries.size }.inject(0){ |sum,item| sum + item }

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