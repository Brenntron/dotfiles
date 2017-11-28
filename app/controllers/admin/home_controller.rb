class Admin::HomeController < ApplicationController
  layout 'admin'
  before_action { authorize!(:manage, Admin) }

  def index
    byebug
  end

end

