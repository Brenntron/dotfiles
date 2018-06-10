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
    @entries = @dispute.dispute_entries
  end

  def update
  end

  def dashboard
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
