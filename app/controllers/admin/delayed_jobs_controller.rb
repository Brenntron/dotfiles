module Admin
  class DelayedJobsController < ApplicationController
    before_action { authorize!(:manage, Admin) }

    def index
      @delayed_jobs = DelayedJob.all
    end

    def start_import
      DelayedJob.run_rake("bugs:import_all",current_user,bugzilla_session)
      render json: "", status: 200
    end

    def create

    end
    def show

    end

  end
end
