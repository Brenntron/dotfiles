class Escalations::Sdr::DisputesController < ApplicationController
  # load_and_authorize_resource class: 'Dispute'

  before_action :require_login

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: SdrDisputeDatatable.new(params, initialize_params, user: current_user)
      end
    end
  end

  private

    def datatables_search_params
      params.require(:search).permit(:value)
    end

    def robust_search_params
      params.permit(:search, :search_type, :search_name)
    end

    def search_conditions
      params.has_key?('search_conditions') ? params.require('search_conditions').permit! : nil
    end

    def initialize_params
      robust_search_params.merge(datatables_search_params).merge('search_conditions' => search_conditions)
    end

    def show
      @dispute = SenderDomainReputationDispute.where(id: params[:id]).first
    end
end
