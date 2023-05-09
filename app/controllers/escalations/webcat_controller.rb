class Escalations::WebcatController < ApplicationController
  before_action :dashboard_metrics

  private   #because in ruby, private is protected not private

  def dashboard_metrics
    @entries_reports = {
        assigned: ComplaintEntry.assigned_count,
        pending: ComplaintEntry.pending_count,
        new: ComplaintEntry.new_count,
        overdue: ComplaintEntry.overdue_count
    }

    @submitter_reports = {
        customer: ComplaintEntry.where(complaint_id: Complaint.from_ti.by_guest.open_comps).count,
        guest: ComplaintEntry.where(complaint_id: Complaint.from_ti.by_cust.open_comps).count,
        internal: ComplaintEntry.where(complaint_id: Complaint.from_int.open_comps).count,
        wBNP: ComplaintEntry.where(complaint_id: Complaint.from_wbnp.open_comps).count
    }

    @complaints_reports ={
        active:Complaint.active_count,
        completed:Complaint.completed_count,
        new: Complaint.new_count,
        overdue:  Complaint.overdue_count
    }
    @complaints_reports ={
        active:Complaint.active_count,
        completed:Complaint.completed_count,
        new: Complaint.new_count,
        overdue:  Complaint.overdue_count
    }
    @jira_reports ={
        complete:JiraImportTask.completed_count,
        failure:JiraImportTask.failed_count,
        pending: JiraImportTask.pending_count + JiraImportTask.awaiting_bast_verdict_count,
        "overall tries":  JiraImportTask.total_count
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

    @jira_new_count = ComplaintEntry.where(complaint_id: Complaint.from_jira).where(status:"NEW").count
    @jira_overdue_count = ComplaintEntry.where(complaint_id: Complaint.from_jira).where.not(status:["RESOLVED", "COMPLETED"]).where("created_at < ?",Time.now - 12.hours).count

    @jira_assigned_count = ComplaintEntry.where(complaint_id: Complaint.from_jira).where(status:"ASSIGNED").count

    @pending_new_count = ComplaintEntry.where(status:"PENDING").count
    @pending_overdue_count = ComplaintEntry.where(status:"PENDING").where("created_at < ?",Time.now - 12.hours).count

  end
end
