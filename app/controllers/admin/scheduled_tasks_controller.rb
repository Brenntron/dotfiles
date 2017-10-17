module Admin
  class ScheduledTasksController < ApplicationController
    before_action { authorize!(:manage, Admin) }
    before_action :set_scheduled_task, only: [:destroy]


    def index
      @scheduled_tasks = Task.where(task_type: "import_all").order(updated_at: :desc)
      @delayed_jobs = DelayedJob.all
    end

    def run_once
      task_type = "import_all" #change to params when we have multiple types
      run_at = 10.seconds.from_now
      if Task.schedule_task(task_type, run_at, current_user, bugzilla_session)
        redirect_to admin_scheduled_tasks_path, :notice => "Job has been queued."
      else
        redirect_to admin_scheduled_tasks_path, :notice => "Job create encountered an error"
      end

    end

    def create

    end

    def show

    end

    # DELETE /roles/1
    # DELETE /roles/1.json
    def destroy
      @scheduled_task.destroy
      respond_to do |format|
        format.html { redirect_to admin_scheduled_tasks_path, notice: 'task was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private
    # Use callbacks to share common setup or constraints between actions.
    def set_scheduled_task
      @scheduled_task = Task.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def role_params
      params.require(:task).permit(:task)
    end

  end
end
