module Admin
  class HomeController < ApplicationController
    before_action { authorize!(:manage, Admin) }

    def index
    end
  end
end
