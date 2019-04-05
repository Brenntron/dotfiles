class Escalations::FileRep::DisputesController < ApplicationController

  def index
    respond_to do |format|
      format.html {  }
      format.json do
        render json: FileRepDatatable.new(params)
      end
    end
  end

  def show
  end
end
