class Escalations::OtherAdminTools::ToolsController < ApplicationController
  layout 'admin'
  before_action { authorize!(:manage, Admin) }
  def index

  end

  def tasks
    @available_tasks = AdminTask.available_tasks 
  end

end

