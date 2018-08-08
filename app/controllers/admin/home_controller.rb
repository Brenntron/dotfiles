class Admin::HomeController < ApplicationController
  layout 'admin'

  def index
    authorize!(:read, Admin)
  end
end

