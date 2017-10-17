module Admin
  class ScheduledTasksController < ApplicationController
    before_action { authorize!(:manage, Admin) }

    def index
      @scheduled_tasks = Task.where(task_type: "import_all").order(updated_at: :desc)
      @delayed_jobs = DelayedJob.all
    end

    def run_once
      task_type = "import_all" #change to params when we have multiple types
      @scheduled_task = Task.new(task_type: task_type)
      if @scheduled_task.save
        case task_type
          when "import_all"
            @scheduled_task.delay.run_rake("bugs:import_all",current_user,bugzilla_session)
        end
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
