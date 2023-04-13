class Escalations::Webcat::JiraImportTasksController < ApplicationController
  before_action :require_login

  def index
    respond_to do |format|
      format.json do
        render json: JiraImportTaskDatatable.new(params)
      end
    end
  end
end
