class Admin::HomeController < ApplicationController
  layout 'admin'
  before_action { authorize!(:manage, Admin) }

  def index
  end
end

