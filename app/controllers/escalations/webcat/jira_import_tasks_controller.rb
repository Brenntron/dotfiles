class Escalations::Webcat::JiraImportTasksController < ApplicationController
  before_action :require_login

  def index
    respond_to do |format|
      format.json do
        render json: JiraImportTaskDatatable.new(params)
      end
      format.xlsx do
        workbook = JiraImportTask.export_xlsx(params[:issue_keys])
        send_data workbook.stream.string, filename: "jira_import_tasks_#{Time.now.utc.iso8601}.xlsx", disposition: 'attachment'
      end
    end
  end
end
