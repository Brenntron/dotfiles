class UsersController < ApplicationController

  before_filter :require_login

  def index
    @users = current_user.team_members
  end

  def show
    @users = current_user.team_members
    @user = User.find(params[:id])
  end

  private

  def require_login
    redirect_to root_url if !current_user
  end

end