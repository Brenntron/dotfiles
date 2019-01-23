class UsersController < ApplicationController
  load_and_authorize_resource

  #per_page for User show page Closed bugs tab 
  CLOSED_BUGS_PAGINATION_SIZE = 25
  PENDING_BUGS_PAGINATION_SIZE = 10
  OPEN_BUGS_PAGINATION_SIZE = 10

  before_action :require_login
  before_action :set_query_session

  def index
    @users = current_user.children
  end

  def show
    @user = User.where(id: params[:id]).first
    if @user
      @closed_bugs = @user.bugs.closed.order("created_at DESC").paginate(:page => params[:closed_page], :per_page => CLOSED_BUGS_PAGINATION_SIZE)
      @pending_bugs = @user.bugs.pending.paginate(:page => params[:pending_page], :per_page => PENDING_BUGS_PAGINATION_SIZE)
      @open_bugs = @user.bugs.open_bugs.paginate(:page => params[:open_page], :per_page => OPEN_BUGS_PAGINATION_SIZE)
    end
    case
      when @user.nil?
        flash[:error] = "Could not find user '#{params[:id]}'"
        redirect_to escalations_users_path
      when !current_user.authorized_to_see?( @user.id )
        flash[:error] = 'You are not authorized to view that user.'
        redirect_to escalations_users_path
      else
        @users = current_user.children
    end
  end

  def results
    @users = User.search(params.require(:user).require(:search).permit(:name)).order(:display_name)
  end

  def update
    @user = User.find(params[:id])
    @user.update(user_params)
    if user_api_key_params[:api_key]
      user_api_key = user_api_key_params[:api_key].strip
      if @user.user_api_key && !user_api_key.blank?
        @user.user_api_key.update(user_api_key_params)
      elsif @user.user_api_key && user_api_key.blank?
        @user.user_api_key.destroy
      elsif !@user.user_api_key && !user_api_key.blank?
        @user.create_user_api_key(user_api_key_params)
      else
        @user.create_user_api_key
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

  def status_metrics
    @user = User.find(params[:user_id])
    pending = {}
    reopened = {}
    timeframe = current_user.chart_timeframe_preference
    (timeframe.days.ago.to_date..Date.today).each do |day|
      pending[day.strftime("%b %d, %Y")] = @user.bugs.where('DATE(pending_at) = ?', day).count
      reopened[day.strftime("%b %d, %Y")] = @user.bugs.where('DATE(reopened_at) = ?', day).count
    end
    respond_to do |format|
      format.json {
        render :json => [pending, reopened]
      }
    end
  end

  def time_metrics
    @user = User.find(params[:user_id])
    @work_time_ave = @user.bugs.average(:work_time).try(:round)
    @rework_time_ave = @user.bugs.average(:rework_time).try(:round)
    @review_time_ave = @user.bugs.average(:review_time).try(:round)

    respond_to do |format|
      format.json {
        render :json => [@work_time_ave,
                         @rework_time_ave,
                         @review_time_ave]
      }
    end
  end

  def pending_team_metrics
    respond_to do |format|
      format.json {
        render :json => current_user.team_metrics('pending')
      }
    end
  end

  def resolved_team_metrics
    respond_to do |format|
      format.json {
        render :json => current_user.team_metrics('resolved')
      }
    end
  end

  def time_team_metrics
    respond_to do |format|
      format.json {
        render :json => current_user.team_work_times
      }
    end
  end

  def component_team_metrics
    respond_to do |format|
      format.json {
        render :json => [current_user.team_by_component('Snort Rules'),
                         current_user.team_by_component('SO Rules'),
                         current_user.team_by_component('Malware')]
      }
    end
  end

  private

  def set_query_session
    session[:query] = current_user.default_bug_list
  end

  def user_params
    params.require(:user).permit(:parent_id, :display_name,:cvs_username, :cec_username, :kerberos_login, :committer, :confirmed, :email, :class_level, :metrics_timeframe, role_ids: [])
  end

  def user_api_key_params
    params.require(:user).fetch(:user_api_key, {}).permit(:api_key)
  end
end
