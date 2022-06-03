class UsersController < ApplicationController
  authorize_resource

  before_action :require_login
#per_page for User show page disputes tab
  CLOSED_DISPUTES_PAGINATION_SIZE = 25
  OPEN_DISPUTES_PAGINATION_SIZE = 10

  def index
    @user = if params[:user].nil?
               current_user
             else
               User.find(params[:user])
             end

    @users = @user.children.order(:display_name)
  end

  def show
    @user = User.where(id: params[:id]).first

    if @user
      closed_filerep_disputes = @user.file_reputation_disputes.where(status: "RESOLVED_CLOSED")
      open_filerep_disputes = @user.file_reputation_disputes.where.not(status: "RESOLVED_CLOSED")

      closed_webrep_disputes = @user.disputes.where(status:  "RESOLVED_CLOSED")
      open_webrep_disputes = @user.disputes.where.not(status: "RESOLVED_CLOSED")

      @closed_filerep_page = closed_filerep_disputes.order("created_at DESC").paginate(:page => params[:closed_filerep_page], :per_page => CLOSED_DISPUTES_PAGINATION_SIZE)
      @open_filerep_page = open_filerep_disputes.order("created_at DESC").paginate(:page => params[:closed_filerep_page], :per_page => OPEN_DISPUTES_PAGINATION_SIZE)

      @closed_webrep_page = closed_webrep_disputes.paginate(:page => params[:closed_webrep_page], :per_page => CLOSED_DISPUTES_PAGINATION_SIZE)
      @open_webrep_page = open_webrep_disputes.paginate(:page => params[:open_webrep_page], :per_page => OPEN_DISPUTES_PAGINATION_SIZE)

      @total_closed = closed_filerep_disputes.length + closed_webrep_disputes.length
      @total_open = open_filerep_disputes.length + open_webrep_disputes.length
      @webcat_complaints_filters = [[nil, nil]] + Complaint::FILTER_VIEW_OPTIONS.map { |f| [f[:label], f[:param]] }
      @webcat_complaints_filters += @user.named_searches.where_project_type('Complaint').order(:name).map do |search|
        [search.name, search.name]
      end
      @webcat_complaints_default_filter_value = @user.user_preferences.find_by(name: 'webcat_complaints_filter')&.value
      @webcat_complaints_default_filter_name = @webcat_complaints_filters.to_h.key(@webcat_complaints_default_filter_value)
    end

    case
      when @user.nil?
        flash[:error] = "Could not find user '#{params[:id]}'"
        redirect_to escalations_users_path
      when !current_user.authorized_to_see?( @user.id )
        flash[:error] = 'You are not authorized to view that user.'
        redirect_to escalations_users_path
      else
        @sibling_col = @user.siblings.count.to_f / 2
        @users = current_user.children.order(:display_name)
    end
  end

  def results
    @users = User.search(params.require(:user).require(:search).permit(:name)).order(:display_name)
  end

  def all
    @users = User.all.order(:display_name)
  end

  def update
    @user = User.find(params[:id])
    @user.update(user_params)
    update_settings(@user)
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

  def update_settings(user)
    # just in case if there are few of settings in the future
    settings_params.each do |name, value|
      UserPreference.find_or_create_by(user_id: user.id, name: name).update(value: value)
    end
  end

  def user_params
    params.require(:user).permit(:parent_id, :display_name,:cvs_username, :cec_username, :kerberos_login, :committer, :confirmed, :email, :class_level, :metrics_timeframe, :threatgrid_api_key, :bugzilla_api_key, :sandbox_api_key, role_ids: [])
  end

  def settings_params
    params.require(:settings).permit(:webcat_complaints_filter)
  end

  def user_api_key_params
    params.require(:user).fetch(:user_api_key, {}).permit(:api_key)
  end
end
