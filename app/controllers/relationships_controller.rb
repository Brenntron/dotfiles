class RelationshipsController < ApplicationController
  load_and_authorize_resource class: 'User'

  # REVIEWER - I don't think we need this anymore, pls to confirm.
  # Some of it might need to be ported to the users controller since all relationship stuff is consolidated there
  # Also may need to check for other OLD references to no longer used relationship items
  # routes and tests probably need to be updated too

  before_action :require_login
  before_action :manager_only_access

  def index
    @user = current_user
    @users = @user.available_users.order(:display_name)
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

  def manager_only_access
    if !current_user.has_role?('manager')
      flash[:error] = "You must be a manager to access that page."
      redirect_to escalations_users_path
    end
  end

  def relationship_params
    params.require(:relationship).permit(:user_id, :team_member_id)
  end

end
