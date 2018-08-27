class Admin::DelayedJobsController < Admin::HomeController
  load_and_authorize_resource class: 'Admin'

  def index
    @delayed_jobs = DelayedJob.all
  end
end