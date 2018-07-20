class Admin::HomeController < ApplicationController
  load_and_authorize_resource class: 'Admin'

  layout 'admin'

  def index
  end
end

