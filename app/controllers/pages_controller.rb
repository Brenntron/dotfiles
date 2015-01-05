class PagesController < ApplicationController
  layout 'application'
  # load_and_authorize_resource
  # before_filter :verify_admin
  #
  # #TODO restrict access to cisco ips

  def index
  end

  private

  def verify_admin
    if current_user
      raise CanCan::AccessDenied unless ["admin", "admin-readonly", "user-admin", "release-admin"].include?(current_user.role)
    else
      redirect_to main_app.root_url, :alert => "Please Sign In"
    end
  end
end
