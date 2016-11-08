class UsersController < ApplicationController

  before_filter :require_login
  before_action :authenticate_access, only: [:show]

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

  def authenticate_access
    if !current_user.authorized_user_list.include?(params[:id].to_i)
      flash[:error] = 'You are not authorized to view that user.'
      redirect_to users_path
    end
  end
end