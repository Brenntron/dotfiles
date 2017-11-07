class Admin::ScheduledTasksController < Admin::HomeController
  before_action :set_scheduled_task, only: [:destroy]


  def index
    @scheduled_tasks = Task.where(task_type: "Import all").order(updated_at: :desc)
    @delayed_jobs = DelayedJob.all
  end

  def run_job
    re_run = params[:re_run].nil? ? false : true
    task_type = params[:task_type]
    start_time = params.require(:run_at).permit(:year,:month,:day,:hour,:minute).to_h
    run_at = Time.new(start_time[:year],start_time[:month],start_time[:day],start_time[:hour],start_time[:minute])
    # if Task.schedule_task(task_type, run_at, re_run, current_user, bugzilla_session)
    #   redirect_to admin_scheduled_tasks_path, :notice => "Job has been queued."
    # else
      redirect_to admin_scheduled_tasks_path, :notice => "Job create encountered an error"
    # end

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

end
