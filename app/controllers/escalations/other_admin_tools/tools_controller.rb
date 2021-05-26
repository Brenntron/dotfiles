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

  def rep_tool

  end

  def wbnp_reports
    @wbnp_reports = WbnpReport.order(id: :desc).first(5)
  end

  def manage_escalations_sync

  end

  def status_api

  end

  def rails_c
    authorize! :manage, :rails_c
  end

end

