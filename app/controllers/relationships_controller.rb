class RelationshipsController < ApplicationController

  before_action :require_login
  before_action :manager_only_access

  def index
    @user = current_user
    @users = @user.available_users
  end

  def show
  end

  def member_status
    new_member = User.find(params[:new_member])
    status = new_member.parent_id.nil? ? true : false
    respond_to do |format|
      format.json { head :no_content, new_member: status }
    end
  end

  private

  def require_login
    redirect_to root_url if !current_user
  end

  def manager_only_access
    if !current_user.has_role?('manager')
      flash[:error] = "You must be a manager to access that page."
      redirect_to users_path
    end
  end

  def relationship_params
    params.require(:relationship).permit(:user_id, :team_member_id)
  end

end