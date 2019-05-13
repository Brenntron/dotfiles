class Escalations::FileRep::DisputesController < ApplicationController

  def index
    respond_to do |format|
      format.html {  }
      format.json do
        render json: FileRepDatatable.new(params,
                                          search_params.merge('search_conditions' => search_conditions),
                                          user: current_user)
      end
    end
  end

  def show
    @file_rep_dispute = FileReputationDispute.find(params[:id])
  end

  def naming_guide
    # Sort records by table sequence
    @conventions = AmpNamingConvention.order(:table_sequence).all
  end


  private

  def search_params
    params.permit(:search_type, :search_name)
  end

  def search_conditions
    params.has_key?('search_conditions') ? params.require('search_conditions').permit! : nil
  end
end
