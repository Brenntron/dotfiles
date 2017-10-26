class Admin::HomeController < ApplicationController
  before_action { authorize!(:manage, Admin) }

  def index
  end

end

