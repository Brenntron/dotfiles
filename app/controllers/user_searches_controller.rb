class UserSearchesController < ApplicationController

  before_action :require_login

  def index
  end

  def new
  end

  def create
  end


  private

  def require_login
    redirect_to root_url if !current_user
  end
end
