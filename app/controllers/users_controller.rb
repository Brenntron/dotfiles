class UsersController < ApplicationController
  load_and_authorize_resource

  before_action :require_login

  def index
    @users = current_user.children.order(:display_name)

  end

  def show
    @user = User.where(id: params[:id]).first

    @first_sibling = @user.siblings.first
    @sibling_col = @user.siblings.count.to_f / 2
    @first_child = @user.children.first
    @children_col = @user.children.count.to_f / 2
    case
      when @user.nil?
        flash[:error] = "Could not find user '#{params[:id]}'"
        redirect_to escalations_users_path
      when !current_user.authorized_to_see?( @user.id )
        flash[:error] = 'You are not authorized to view that user.'
        redirect_to escalations_users_path
      else
        @users = current_user.children.order(:display_name)
    end
  end

  def results
    @users = User.search(params.require(:user).require(:search).permit(:name)).order(:display_name)
  end

  def update
    @user = User.find(params[:id])
    @user.update(user_params)
    if user_api_key_params[:api_key]
      if @user.user_api_key
        @user.user_api_key.update(user_api_key_params)
      else
        @user.create_user_api_key(user_api_key_params)
      end
    end
    redirect_back(fallback_location: :back)
    if @user.save
      flash[:notice] = "#{@user.cvs_username} updated successfully."
    else
      flash[:alert] = "Unable to update #{@user.cvs_username}."
    end
  end

  def add_to_team
    @user = User.find(params[:user_id])
    @child = User.where(id: params[:child_id]).first
    if @child
      @child.move_to_child_of(@user)
      if @child.save
        flash[:notice] = "#{@child.cvs_username} successfully added to #{@user.cvs_username}'s team."
      else
        flash[:alert] = "Unable to add #{@child.cvs_username} to #{@user.cvs_username}'s team."
      end
    else
      flash[:alert] = "Please select a team member from the list."
    end
    redirect_back(fallback_location: :back)
  end

  def remove_from_team
    @child = User.find(params[:user_id])
    @child.update(parent_id: nil)
    redirect_back(fallback_location: :back)
    if @child.save
      flash[:notice] = "#{@child.cvs_username} successfully removed from team."
    else
      flash[:alert] = "Unable to remove #{@child.cvs_username} from team."
    end
  end

  private

  def user_params
    params.require(:user).permit(:parent_id, :display_name,:cvs_username, :cec_username, :kerberos_login, :committer, :confirmed, :email, :class_level, :metrics_timeframe, role_ids: [])
  end

  def user_api_key_params
    params.require(:user).fetch(:user_api_key, {}).permit(:api_key)
  end
end
