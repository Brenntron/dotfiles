class RelationshipsController < ApplicationController

  before_filter :require_login

  def index
    @user = current_user
    team = @user.team_members.map{|t| t.id} << @user.id
    @users = User.all.reject{|u| team.include?(u.id)}
  end

  def show
  end

  def create
    @user = User.find(params[:user_id])
    Relationship.create(relationship_params)
    redirect_to user_relationships_path(@user)
  end

  def destroy
    @user = User.find(params[:user_id])
    @relationship = Relationship.find(params[:id])
    @relationship.destroy

    flash[:notice] = 'Team member has been removed'
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

  def relationship_params
    params.require(:relationship).permit(:user_id, :team_member_id)
  end

end