class Escalations::OtherAdminTools::ToolsController < ApplicationController
  layout 'admin'
  before_action { authorize!(:manage, Admin) }
  def index

  end

  def tasks
    @available_tasks = AdminTask.available_tasks 
  end

  def rule_api

  end

  def wbnp_reports
    @wbnp_reports = WbnpReport.all
  end

end

