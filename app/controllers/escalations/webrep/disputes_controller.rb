class Escalations::Webrep::DisputesController < ApplicationController

  before_action :require_login

  def index
    respond_to do |format|
      format.html
      format.csv do
        @disputes = Dispute.robust_search(params.fetch(:dispute, {})['search_type'],
                                          search_name: params.fetch(:dispute, {})['search_name'],
                                          params: index_params,
                                          user: current_user)
        contents = CSV.generate do |csv|
          csv << [ 'Priority', 'Case ID', 'Status', 'Dispute', 'Count', 'Owner', 'Time Submitted', 'Age' ]
          @disputes.each do |dispute|
            csv << [
                'P3',
                dispute.case_number,
                dispute.status,
                dispute.org_domain,
                dispute.dispute_entries.count,
                dispute.user.cvs_username,
                dispute.case_opened_at,
                ApplicationRecord.humanize_secs(Time.now - dispute.case_opened_at)
            ]
          end
        end
        send_data contents
      end
    end
  end

  def show
    @dispute = Dispute.find(params[:id])
    @versioned_items = @dispute.compose_versioned_items

    @entries = @dispute.dispute_entries
    @entries.each { |entry| entry.blacklist(reload: true) }
  end

  def update
  end

  def dashboard
  end

  def research
    # This is temporary till we get the searched hooked up
    @entries = DisputeEntry.all.limit(5)
  end

  def tickets
  end
  
  def advanced_search
    @dispute = Dispute.new
  end

  def named_search
  end

  def standard_search
  end

  def contains_search
  end

  private

  def index_params
    params.fetch(:dispute, {}).permit(:customer_name, :customer_email, :customer_company_name,
                                      :status, :resolution, :subject,
                                      :value)
  end
end
