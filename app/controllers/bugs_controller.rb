class BugsController < ApplicationController
  load_and_authorize_resource except: [:add_tag, :remove_tag]

  before_action :require_login
  before_action :query_bugs
  before_action :get_states_and_users, only: [:index, :show, :new]
  after_action  :sync_summary, only: [:create, :add_tag, :remove_tag]

  def index
    if params[:bug].present?
      @bug_searchID = params[:bug][:searchID]
      if @bug_searchID
        @bugs = Bug.where("id LIKE ?", "%#{params[:bug][:searchID]}%")
      end
    end
  end

  def new
    @bug = current_user.bugs.build
    @tags = Tag.all.map { |tag| tag.name }.join(',')
  end

  def create
    options = bug_params
    options[:creator] = current_user.id
    new_bug = Bugzilla::Bug.new(bugzilla_session).create(options.to_h) #the bugzilla session is where we authenticate
    new_bug_id = new_bug["id"]
    @tags=params[:bug][:tag_names]
    @bug = Bug.new(
        :id => new_bug_id,
        :bugzilla_id => new_bug_id,
        :product => params[:bug][:product],
        :component => params[:bug][:component],
        :summary => params[:bug][:summary],
        :version => params[:bug][:version],
        :description => params[:bug][:description],
        :state => params[:bug][:state] || 'OPEN',
        :status => params[:bug][:status] || 'NEW',
        :resolution => params[:bug][:resolution] || 'OPEN',
        :creator => current_user.id,
        :user_id => current_user.id,
        :opsys => params[:bug][:opsys],
        :platform => params[:bug][:platform],
        :priority => params[:bug][:priority],
        :severity => params[:bug][:severity],
        :classification => params[:bug][:classification] || 0
    )

    if @bug.save
      @tags.each { |tag| @bug.tags << Tag.find_or_create_by(name: tag.upcase) } if @tags
      redirect_to @bug
    end
  end

  def show
    @bug = Bug.where(id: params[:id]).first()
    if @bug
      @rules = @bug.rules.sort { |a, b| a.sort_rules_by_state <=> b.sort_rules_by_state }
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
      @tags = Tag.all.map { |tag| tag.name }.join(',')
      @categories = RuleCategory.all.sort_by { |x| [-x.rules.count, x.category] }
    else
      redirect_to '/bugs'
      flash[:error] = "Could not find bug #{params[:id]}"
    end
  end

  def update
    @bug = Bug.find(params[:id])
    Bugzilla::Bug.new(bugzilla_session).update(get_params_hash(params).to_h)
    if @bug.update(bug_params)
      redirect_to @bug
    else
      render json: @bug.errors, status: 422
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

  private

  def bug_params
    params.require(:bug).permit(:product, :component, :state, :creator, :opsys, :severity, :platform, :priority, :classification, :searchID,
                                :summary, :version, :description, :user_id, :committer_id, rules_attributes: [:connection, :flow, :message, :reference,
                                                                                                              :metadata, :detection, :class_type, :reference], tag_ids: [])
  end

  def sync_summary
    @bug.compose_summary
  end


  def query_bugs
    if params[:q]
      session[:query] = params[:q]
    elsif params[:bug].present?
      session[:query] = "advance-search"
      session[:search] = params[:bug]
    else
      session[:query] = ""
    end
    if session[:query]
      case session[:query]
        when "my-bugs"
          @bugs = current_user.bugs
        when "team-bugs"
          if current_user.has_role?('manager')
            @bugs = current_user.children.map{ |cw| cw.bugs }[0] || []
          else
            @bugs = current_user.siblings.map{ |cw| cw.bugs }[0] || []
          end
        when "open-bugs"
          @bugs = Bug.open
        when "pending-bugs"
          @bugs = Bug.pending
        when "fixed-bugs"
          @bugs = Bug.closed
        when "advance-search"
          @bugs = Bug.bugs_with_search(session[:search])
        when "all-bugs"
          @bugs = Bug.all
        else
          @bugs = current_user.default_bug_list
      end
    else
      @bugs = current_user.default_bug_list
    end
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
    @users = User.all
  end

  def require_login
    redirect_to root_url if !current_user
  end

end