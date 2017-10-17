module Admin
  class ScheduledTasksController < ApplicationController
    before_action { authorize!(:manage, Admin) }

    def index
      @scheduled_tasks = Task.all
      @delayed_jobs = DelayedJob.all
    end

    def run_once
      @scheduled_task = Task.new(task_type: "import_all")
      if @scheduled_task.save
        @scheduled_task.delay.run_rake("bugs:import_all",current_user,bugzilla_session)
        redirect_to admin_scheduled_tasks_path, :notice => "Job has been queued."
      else
        redirect_to admin_scheduled_tasks_path, :notice => "Job create encountered an error"
      end

    end

    def create

    end

    def show

    end

  end
end
