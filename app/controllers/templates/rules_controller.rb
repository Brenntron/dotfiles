class Templates::RulesController < ApplicationController
  def show
    @rule = Rule.find(params[:id])
    @template = params[:template]
    render action: @template
  end
end
