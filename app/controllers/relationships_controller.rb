class RelationshipsController < ApplicationController

  before_action :require_login
  before_action :manager_only_access

  def index
    @user = current_user
    team = @user.team_members.map{|t| t.id} << @user.id
    @users = User.all.reject{|u| team.include?(u.id)}
  end

  def show
  end

  def create
    @user = User.find(params[:user_id])
    r = Relationship.create(relationship_params)
    if r.save
      flash[:notice] = "#{r.team_member.cvs_username} is now on your team!"
    else
      flash[:error] = 'Something went wrong.'
    end
    redirect_to user_relationships_path(@user)
  end

  def destroy
    @user = User.find(params[:user_id])
    @relationship = Relationship.find(params[:id])
    @team_member = @relationship.team_member.cvs_username
    @relationship.destroy

    flash[:alert] = "#{@team_member} has been removed from your team."
    redirect_to user_relationships_path(@user)
  end

  def member_status
    new_member = params[:new_member]
    member_status = Relationship.where(team_member_id: new_member)
    status = member_status.empty? ? true : false
    respond_to do |format|
      format.json { head :no_content, new_member: status }
    end
  end

  private

  def require_login
    redirect_to root_url if !current_user
  end

  def manager_only_access
    if !current_user.manager?
      flash[:error] = "You must be a manager to access that page."
      redirect_to users_path
    end
  end

  def relationship_params
    params.require(:relationship).permit(:user_id, :team_member_id)
  end

end