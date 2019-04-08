class Escalations::FileRep::DisputesController < ApplicationController

  def index
    respond_to do |format|
      format.html {  }
      format.json do
        render json: FileRepDatatable.new(params, {}, search_name: params['search_name'])
      end
    end
  end

  def show
    @file_rep_dispute = FileReputationDispute.find(params[:id])
  end
end
