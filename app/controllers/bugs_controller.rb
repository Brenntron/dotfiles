class BugsController < ApplicationController

  before_filter :query_bugs

  def index
    @users = User.all
    @states = Bug.uniq.pluck(:state)
    if params[:q]
      case params[:q]
        when "my-bugs"
          @bugs = current_user.bugs
        when "team-bugs"
          @bugs = current_user.bugs
        when "open-bugs"
          @bugs = current_user.bugs
        when "pending-bugs"
          @bugs = current_user.bugs
        when "fixed-bugs"
          @bugs = Bug.where(state: "FIXED")
        else
          @bugs = Bug.all
      end
    elsif params[:bug]
      @bugs = bugs_with_search(params[:bug])
    else
      @bugs = current_user.bugs
    end
  end

  def new
    @users = User.all
    @states = Bug.uniq.pluck(:state)
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
    @attachments = @bug.attachments.where(is_obsolete: false)
    @obsolete_attachments = @bug.attachments.where(is_obsolete: true)
    @tasks = @bug.tasks
    @notes = @bug.notes.order(created_at: :desc)
    @users = User.all
    @states = Bug.uniq.pluck(:state)
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
    params.require(:bug).permit(:product, :component, :state, :creator, :opsys, :severity, :platform, :priority, :classification,
                                :summary, :version, :description, :user_id, :committer_id, rules_attributes: [:connection, :flow, :message, :reference,
                                                                                               :metadata, :detection, :class_type, :reference])
  end

  def query_bugs
    session[:query] = params[:q] if params[:q]
    if session[:query]
      case session[:query]
        when "my-bugs"
          @bugs = current_user.bugs
        when "team-bugs"
          @bugs = current_user.bugs
        when "open-bugs"
          @bugs = current_user.bugs
        when "pending-bugs"
          @bugs = current_user.bugs
        when "fixed-bugs"
          @bugs = Bug.where(state: "FIXED")
        else
          @bugs = Bug.all
      end
    else
      @bugs = current_user.bugs
    end
  end

  def bugs_with_search(param)
    if param[:bugzilla_max] == ''
      param.delete_if { |k,v| v == "" }
      count = 0
      query = ''
      param.each do |k,v|
        count = count+1
        query = query + k + "='" + v + "'"
        query = query + " && " if count != param.count
      end
      Bug.where(query)
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

end