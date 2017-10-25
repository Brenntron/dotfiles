class BugsController < ApplicationController
  load_and_authorize_resource except: [:add_tag, :remove_tag, :show, :bug_metrics]

  before_action :require_login
  before_action :query_bugs
  before_action :check_bug_permission, only: [:show]
  before_action :get_states_and_users, only: [:index, :show, :new]
  after_action  :sync_summary, only: [:add_tag, :remove_tag]


  def index

    session[:query] = session[:query].blank? ? current_user.default_bug_list : session[:query]
    if params[:saved_search_id].present?
      saved_search = SavedSearch.where({:id => params[:saved_search_id], :user_id => current_user.id}).first
      if saved_search.present?
        session[:query] = saved_search.session_query
        session[:search] = JSON.parse(saved_search.session_search)
      end
    end
    @bug_query = Bug.query(current_user, session[:query], session[:search])
    if params[:bug].present? && params[:bug][:saved_search].present?
      SavedSearch.create({:user_id => current_user.id, :name => params[:bug][:saved_search], :session_query => session[:query], :session_search => session[:search].to_json})
    end

    if @bug_query.any?
      @bugs = @bug_query.permit_class_level(current_user.class_level).paginate(:page => session[:page], :per_page => 32)
    else
      if flash.now[:alert]
        flash.now[:alert] += " Zarro Boogs found, please try selecting any other filter."
      else
        flash.now[:alert] = "Zarro Boogs found, please try selecting any other filter."
      end
      @bugs = Bug.none.paginate(:page => session[:page], :per_page => 32)
    end
    if params[:bug].present?
      @bug_search_id = params[:bug][:id]
      if @bug_search_id.present?
        @bug_search_max = params[:bug][:bugzilla_max]
        if @bug_search_max.present?
          @bugs =
              Bug.where("id BETWEEN ? AND ?", params[:bug][:id], params[:bug][:bugzilla_max]).permit_class_level(current_user.class_level)
                  .paginate(:page => session[:page], :per_page => 32)
          @bug_search_id = '' # otherwise the form will show the lower end of the range
        else
          @bugs =
              Bug.where("id LIKE ?", "%#{params[:bug][:id]}%").permit_class_level(current_user.class_level)
                  .paginate(:page => session[:page], :per_page => 32)
        end
      end
    end
  end

  def new
    @bug = current_user.bugs.build
    @tags = Tag.all.map { |tag| tag.name }.join(',')
  end

  def create
    respond_to do |format|
      format.js { head :no_content }
    end
  end

  def show
    @bug = Bug.where(id: params[:id]).first
    @bug_references =  Reference.joins(rules: :bugs).where(bugs: {id: @bug.id })

    if @bug
      @show_resolve_button = ['NEW', 'OPEN', 'ASSIGNED', 'DUPLICATE', 'REOPENED'].include?(@bug.state)
      @rules = @bug.rules.active.sort { |left, right| left <=> right }
      @ref_types = ReferenceType.valid_reference_types
      @pcap_attachments = []
      @other_attachments = []
      @bug.attachments.where(is_obsolete: false).map do |att|
        if att.file_name.include? '.pcap'
          @pcap_attachments << att
        else
          @other_attachments << att
        end
      end
      @obsolete_attachments = @bug.attachments.where(is_obsolete: true)
      @tasks = @bug.tasks.order(created_at: :desc)
      @notes = @bug.notes.published.order(created_at: :desc)
      @tags = Tag.all.map { |tag| tag.name }.join(',')
      @categories = RuleCategory.ranked
      flash.now[:alert] = "Looks like this bug (#{@bug.id}) may be out of synch with bugzilla.
                       Please 'resynch' using the button below." if @bug.bugzilla_synch_needed?
    else
      redirect_to '/bugs'
      flash[:error] = "Could not find bug #{params[:id]}"
    end
  end

  def update
    @bug = Bug.find(params[:id])
    respond_to do |format|
      format.js { head :no_content }
    end
  end

  def add_tag
    @bug = Bug.find(params[:bug][:id])
    @tag = Tag.find_or_create_by(name: params[:bug][:tag_name].upcase)
    @bug.tags << @tag
    respond_to do |format|
      format.json { head :no_content }
    end
  end

  def remove_tag
    @bug = Bug.find(params[:bug][:id])
    @tag = Tag.find_by(name: params[:bug][:tag_name])
    @bug.tags.destroy(@tag)
    respond_to do |format|
      format.json { head :no_content }
    end
  end

  def bug_metrics
    @bug = Bug.find(params[:bug_id])

    respond_to do |format|
      format.json {
        render :json => [@bug.work_time,
                         @bug.rework_time,
                         @bug.review_time,
                         @bug.resolution_time]
      }
    end
  end

  private

  def bug_params
    params.require(:bug).permit(:product, :component, :state, :creator, :opsys, :severity, :platform, :priority, :classification, :searchID,
                                :summary, :whiteboard, :version, :description, :user_id, :committer_id, rules_attributes: [:connection, :flow, :message, :reference,
                                                                                                              :metadata, :detection, :class_type, :reference], tag_names: [])
  end

  def query_params
    params.require(:bug).permit(:id, :bugzilla_max, :summary, :user_id, :committer_id, :state, :whiteboard, :component)
        .reject { |key, value| (value.blank? || value.is_a?(Array) || key =='tag_name') }
  end

  def sync_summary
    @bug.compose_summary
    Bugzilla::Bug.new(bugzilla_session).update(ids: @bug.id, summary: @bug.summary)
  end

  def query_bugs
    if params[:q]
      session[:query] = params[:q]
      session[:page] = "1"
    elsif params[:bug].present?
      session[:query] = "advance-search"
      session[:search] = query_params
      session[:page] = "1"
    else
      session[:query] = session[:query] || ''
    end
    session[:page] = params[:page] || session[:page]
  end

  def get_params_hash(params)
    para_hash = {}
    params[:bug].each do |k, v|
      para_hash[k] = v
    end
    para_hash[:ids] = params[:id]
    para_hash
  end

  def get_states_and_users
    @states = Bug.distinct.pluck(:state)
    @users = User.order(:cvs_username).all
  end

  def check_bug_permission
    bug = Bug.where(id: params[:id]).first
    case
      when bug.nil?
        redirect_to '/bugs'
        flash[:error] = "Couldn't find Bug #{params[:id]}"
      when !bug.check_permission(current_user)
        redirect_to '/bugs'
        flash[:error] = "You dont have permission to access bug: #{params[:id]}"
    end
  end
end
