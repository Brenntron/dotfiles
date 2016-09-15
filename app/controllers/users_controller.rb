class UsersController < ApplicationController

  before_filter :require_login

  def index
    @users = User.all
  end

  def show
    @users = User.all
    @user = User.find(params[:id])
  end

  private

  def require_login
    redirect_to root_url if !current_user
  end

end