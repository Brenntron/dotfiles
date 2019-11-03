class Escalations::WebcatController < ApplicationController
  before_action :dashboard_metrics

  private   #because in ruby, private is protected not private

  def dashboard_metrics
    @assigned = ComplaintEntry.assigned_count
    @pending = ComplaintEntry.pending_count
    @new = ComplaintEntry.new_count
    @overdue = ComplaintEntry.overdue_count

    @ti_comp_guest = ComplaintEntry.where(complaint_id: Complaint.from_ti.by_guest.open_comps).count
    @ti_comp_cust = ComplaintEntry.where(complaint_id: Complaint.from_ti.by_cust.open_comps).count
    @int_comp_entries = ComplaintEntry.where(complaint_id: Complaint.from_int.open_comps).count
    @wbnp = ComplaintEntry.where(complaint_id: Complaint.from_wbnp.open_comps).count

    @active_comp = Complaint.active_count
    @completed_comp = Complaint.completed_count
    @new_comp = Complaint.new_count
    @overdue_comp = Complaint.overdue_count

    @ti_new_count = Complaint.ti_new_count
    @ti_overdue_count = Complaint.ti_overdue_count
    @ti_assigned_count = ComplaintEntry.where(complaint_id: Complaint.from_ti).where(status:"ASSIGNED").count

    @wbnp_new_count = Complaint.wbnp_new_count
    @wbnp_overdue_count = Complaint.wbnp_overdue_count
    @wbnp_assigned_count = ComplaintEntry.where(complaint_id: Complaint.from_wbnp).where(status:"ASSIGNED").count

    @int_new_count = Complaint.int_new_count
    @int_overdue_count = Complaint.int_overdue_count
    @int_assigned_count = ComplaintEntry.where(complaint_id: Complaint.from_int).where(status:"ASSIGNED").count

    @pending_new_count = ComplaintEntry.where(status:"PENDING").count
    @pending_overdue_count = ComplaintEntry.where(status:"PENDING").overdue_count

  end
end
