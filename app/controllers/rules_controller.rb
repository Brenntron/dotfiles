class RulesController < ApplicationController
  def get_impact
    classification = params[:classification]
    respond_to do |format|
      format.js {
        render :js => RulesHelper::CLASSIFICATION[classification]
      }
    end
  end
end
