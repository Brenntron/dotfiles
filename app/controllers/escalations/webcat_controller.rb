class Escalations::WebcatController < ApplicationController
  before_action :dashboard_metrics

  private   #because in ruby, private is protected not private

  def dashboard_metrics
    @entries_reports = {
        Assigned: ComplaintEntry.assigned_count,
        Pending: ComplaintEntry.pending_count,
        New: ComplaintEntry.new_count,
        Overdue: ComplaintEntry.overdue_count
    }

    @submitter_reports = {
        Customer: ComplaintEntry.where(complaint_id: Complaint.from_ti.by_guest.open_comps).count,
        Guest: ComplaintEntry.where(complaint_id: Complaint.from_ti.by_guest.open_comps).count,
        Internal: ComplaintEntry.where(complaint_id: Complaint.from_int.open_comps).count,
        WBNP: ComplaintEntry.where(complaint_id: Complaint.from_wbnp.open_comps).count
    }

    @complaints_reports ={
        Active:Complaint.active_count,
        Completed:Complaint.completed_count,
        New: Complaint.new_count,
        Overdue:  Complaint.overdue_count
    }

    @ti_new_count = ComplaintEntry.where(complaint_id: Complaint.from_ti).where(status:"NEW").count
    @ti_overdue_count = ComplaintEntry.where(complaint_id: Complaint.from_ti).where.not(status:["RESOLVED", "COMPLETED"]).where("created_at < ?",Time.now - 12.hours).count
    @ti_assigned_count = ComplaintEntry.where(complaint_id: Complaint.from_ti).where(status:"ASSIGNED").count

    @wbnp_new_count = ComplaintEntry.where(complaint_id: Complaint.from_wbnp).where(status:"NEW").count
    @wbnp_overdue_count = ComplaintEntry.where(complaint_id: Complaint.from_wbnp).where.not(status:["RESOLVED","COMPLETED"]).where("created_at < ?",Time.now - 12.hours).count
    @wbnp_assigned_count = ComplaintEntry.where(complaint_id: Complaint.from_wbnp).where(status:"ASSIGNED").count

    @int_new_count = ComplaintEntry.where(complaint_id: Complaint.from_int).where(status:"NEW").count
    @int_overdue_count = ComplaintEntry.where(complaint_id: Complaint.from_int).where.not(status:["RESOLVED","COMPLETED"]).where("created_at < ?",Time.now - 12.hours).count
    @int_assigned_count = ComplaintEntry.where(complaint_id: Complaint.from_int).where(status:"ASSIGNED").count

    @pending_new_count = ComplaintEntry.where(status:"PENDING").count
    @pending_overdue_count = ComplaintEntry.where(status:"PENDING").where("created_at < ?",Time.now - 12.hours).count

  end
end
