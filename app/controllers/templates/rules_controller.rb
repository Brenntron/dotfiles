class Templates::RulesController < ApplicationController
  before_action :set_rule

  private

  def set_rule
    @rule = Rule.find(params[:rule_id])
  end
end
