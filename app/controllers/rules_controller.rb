class RulesController < ApplicationController
  # load and auth added just in case actions are re-added.
  load_and_authorize_resource except: [:get_impact, :export]

  def get_impact
    classification = params[:classification]
    respond_to do |format|
      format.js {
        render :js => RulesHelper::CLASSIFICATION[classification]
      }
    end
  end

  def export
    send_file RuleSyntax::RuleExporter.new(params).export 
  end
end
