class Escalations::OtherAdminTools::ToolsController < ApplicationController
  layout 'admin'
  before_action { authorize!(:manage, Admin) }
  def index

  end

  def tasks
    @available_tasks = AdminTask.available_tasks 
  end

  def execute_tasks
    task_name = params[:name]
    task_arguments = params[:task_arguments]

    AdminTask.process_task(task_name, task_arguments)
  end  
end

