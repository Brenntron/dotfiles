class UsersController < ApplicationController

  before_action :require_login

  def index
    @users = current_user.team_members
  end

  def show
    @user = User.where(id: params[:id]).first
    case
      when @user.nil?
        redirect_to users_path
        flash[:error] = "Could not find user '#{params[:id]}'"
      else
        if !current_user.authorized_user_list.include?(params[:id].to_i)
          flash[:error] = 'You are not authorized to view that user.'
          redirect_to users_path
        else
          @users = current_user.team_members
        end
    end
  end

  def results
    @users = User.search(params.require(:user).require(:search).permit(:name))
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
                         @review_time_ave,
                         @user.average_resolution_times]
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

  def require_login
    redirect_to root_url if !current_user
  end

  def user_params
    params.require(:user).permit(:display_name, :committer, :confirmed, :email, :role, :class_level, :metrics_timeframe)
  end
end