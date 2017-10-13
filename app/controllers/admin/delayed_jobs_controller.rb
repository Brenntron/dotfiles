module Admin
  class DelayedJobsController < ApplicationController
    before_action { authorize!(:manage, Admin) }

    def index
      @delayed_jobs = DelayedJob.all
    end
    def create

    end
    def show

    end

  end
end
