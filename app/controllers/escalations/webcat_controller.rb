class Escalations::WebcatController < ApplicationController
  before_action :dashboard_metrics

  private   #because in ruby, private is protected not private

  def dashboard_metrics
    @ti_comp_guest = ComplaintEntry.where(complaint_id: Complaint.from_ti.by_guest.open_comps).count
    @ti_comp_cust = ComplaintEntry.where(complaint_id: Complaint.from_ti.by_cust.open_comps).count
    @int_comp_entries = ComplaintEntry.where(complaint_id: Complaint.from_int.open_comps).count
    @wbnp = ComplaintEntry.where(complaint_id: Complaint.from_wbnp.open_comps).count

    @active_comp = Complaint.active_count
    @completed_comp = Complaint.completed_count
    @new_comp = Complaint.new_count
    @overdue_comp = Complaint.overdue_count


    # FIGURE THIS OUT
    @dan_var = Complaint.dan_count

    # NEED VARIABLES FOR:
    # ticket_source == 'talos-intelligence' AND complaints.status.count of NEW
    # ticket_source == 'talos-intelligence' AND complaints.status.count of OVERDUE
    # ticket_source == 'talos-intelligence' AND complaints.status.count of ASSIGNED

    # ticket_source == 'RuleUI' AND complaints.status.count of NEW
    # ticket_source == 'RuleUI' AND complaints.status.count of OVERDUE
    # ticket_source == 'RuleUI' AND complaints.status.count of ASSIGNED

    # ticket_source == NULL AND complaints.status.count of NEW
    # ticket_source == NULL AND complaints.status.count of OVERDUE
    # ticket_source == NULL AND complaints.status.count of ASSIGNED


    @assigned = ComplaintEntry.assigned_count
    @pending = ComplaintEntry.pending_count
    @new = ComplaintEntry.new_count
    @overdue = ComplaintEntry.overdue_count

  end
end
