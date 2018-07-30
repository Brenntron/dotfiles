class Escalations::WebcatController < ApplicationController
  before_action :require_login
  before_action :dashboard_metrics

  def dashboard_metrics
    @secHub_1 = 0
    @secHub_2 = 0
    @ss = 0
    @int_1 = 0
    @int_2 = 0
    @wbnp = 0

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