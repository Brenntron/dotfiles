class Escalations::FileRep::DisputesController < ApplicationController
  load_and_authorize_resource class: 'FileReputationDispute'

  def index
    respond_to do |format|
      format.html {  }
      format.json do
        render json: FileRepDatatable.new(params)
      end
    end
  end

  def show
    @file_rep_dispute = FileReputationDispute.find(params[:id])
  end
end