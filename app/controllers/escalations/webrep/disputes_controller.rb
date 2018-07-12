class Escalations::Webrep::DisputesController < ApplicationController

  before_action :require_login

  def index
    @disputes = Dispute.robust_search(params.fetch(:dispute, {})['search_type'],
                                      search_name: params.fetch(:dispute, {})['search_name'],
                                      params: index_params,
                                      user: current_user)
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

  def resolution_report
    @report = DisputeReport::ResolutionReport.new(date_from: params['report']['date_from'],
                                                  date_to: params['report']['date_to'])
  end

  def resolution_age_report
    @entries = DisputeEntry.from_age_report_params(age_report_params)
  end

  private

  def index_params
    params.fetch(:dispute, {}).permit(:customer_name, :customer_email, :customer_company_name,
                                      :status, :resolution, :subject,
                                      :value)
  end

  def age_report_params
    params.permit(:date, :resolution, :engineer)
  end
end
