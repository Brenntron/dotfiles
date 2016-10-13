class BugsController < ApplicationController

  before_filter :require_login
  before_filter :query_bugs
  before_filter :get_states_and_users, only: [:index, :show, :new]

  def index
    if params[:bug].present?
      @bug_searchID = params[:bug][:searchID]
      @bugs = Bug.where("id LIKE ?", "%#{params[:bug][:searchID]}%")
    end
  end

  def new
    @bug = current_user.bugs.build
  end

  def create
    options = bug_params
    options[:creator] = current_user.id
    new_bug = Bugzilla::Bug.new(bugzilla_session).create(options) #the bugzilla session is where we authenticate
    new_bug_id = new_bug["id"]
    @bug = Bug.new(
        :id => new_bug_id,
        :bugzilla_id => new_bug_id,
        :product => params[:bug][:product],
        :component => params[:bug][:component],
        :summary => params[:bug][:summary],
        :version => params[:bug][:version],
        :description => params[:bug][:description],
        :state => params[:bug][:state] || 'OPEN',
        :creator => current_user.id,
        :user_id => current_user.id,
        :opsys => params[:bug][:opsys],
        :platform => params[:bug][:platform],
        :priority => params[:bug][:priority],
        :severity => params[:bug][:severity],
        :classification => params[:bug][:classification] || 0
    )
    if @bug.save
      redirect_to @bug
    end
  end

  def show
    @bug = Bug.find(params[:id])
    @rules = @bug.rules
    @ref_types = ReferenceType.all
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
    @tasks = @bug.tasks
    @notes = @bug.notes.order(created_at: :desc)
  end

  def update
    @bug = Bug.find(params[:id])
    Bugzilla::Bug.new(bugzilla_session).update(get_params_hash(params))
    if @bug.update(bug_params)
      render json: @bug
    else
      render json: @bug.errors, status: 422
    end
  end

  private

  def bug_params
    params.require(:bug).permit(:product, :component, :state, :creator, :opsys, :severity, :platform, :priority, :classification, :searchID,
                                :summary, :version, :description, :user_id, :committer_id, rules_attributes: [:connection, :flow, :message, :reference,
                                                                                               :metadata, :detection, :class_type, :reference])
  end

  def query_bugs
    if params[:q]
      session[:query] = params[:q]
    elsif params[:bug].is_a? Hash
      session[:query] = "advance-search"
      session[:search] = params[:bug]
    end
    if session[:query]
      case session[:query]
        when "my-bugs"
          @bugs = current_user.bugs
        when "team-bugs"
          @bugs = current_user.bugs
        when "open-bugs"
          @bugs = Bug.where(state: "OPEN")
        when "pending-bugs"
          @bugs = Bug.where(state: "PENDING")
        when "fixed-bugs"
          @bugs = Bug.where(state: "FIXED")
        when "advance-search"
          @bugs = Bug.bugs_with_search(session[:search])
        else
          @bugs = Bug.all
      end
    else
      @bugs = current_user.bugs
    end
  end

  def get_params_hash(params)
    para_hash = {}
    params[:bug].each do |k,v|
      para_hash[k] = v
    end
    para_hash[:ids] = params[:id]
    para_hash
  end

  def get_states_and_users
    @states = Bug.uniq.pluck(:state)
    @users = User.all
  end

  def require_login
    redirect_to root_url if !current_user
  end

end