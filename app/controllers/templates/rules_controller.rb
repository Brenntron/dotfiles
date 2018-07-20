class Templates::RulesController < ApplicationController
  load_and_authorize_resource class: 'Admin'

  def show
    @rule = Rule.find(params[:id])
    @template = params[:template]
    render action: @template
  end
end
