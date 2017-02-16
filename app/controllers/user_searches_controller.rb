class UserSearchesController < ApplicationController

  before_action :require_login

  def new
  end

  def create
    @users = User.search(params[:user_search])
  end


  private

  def require_login
    redirect_to root_url if !current_user
  end
end
