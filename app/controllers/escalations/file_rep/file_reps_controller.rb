class Escalations::FileRep::FileRepsController < ApplicationController
  def index
    respond_to do |format|
      format.html {  }
      format.json do
        render json: FileRepDatatable.new(params)
      end
    end
  end
end
