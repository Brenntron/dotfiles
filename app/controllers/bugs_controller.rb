class BugsController < ApplicationController

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

  def show
    @bug = Bug.find(params[:id])
    @rules = @bug.rules
    @ref_types = ReferenceType.all
    @attachments = @bug.attachments.where(is_obsolete: false)
    @obsolete_attachments = @bug.attachments.where(is_obsolete: true)
    @tasks = @bug.tasks
    @notes = @bug.notes
  end

  def update
    @bug = Bug.find(params[:id])
    xmlrpc = Bugzilla::XMLRPC.new(Rails.configuration.bugzilla_host)
    if current_user
      xmlrpc.token = request.headers['Xmlrpc-Token']
    end
    Bugzilla::Bug.new(xmlrpc).update({ids: params[:id], summary: params[:bug][:summary]})
    if @bug.update(bug_params)
      render json: @bug
    else
      render json: @bug.errors, status: 422
    end
  end

  def create_rules
    @bug = Bug.find(params[:id])
    params[:bug][:rules].each do |rule|
      new_rule = Rule.new
      new_rule['message'] = rule['message']
      new_rule['detection'] = rule['detection']
      new_rule['class_type'] = rule['class_type']
      [:connection, :flow, :metadata].each do |data|
        new_rule[data] = rule[data].join(" ") if rule[data].is_a? Array
      end
      if new_rule.save
        @bug.rules << new_rule
        new_rule.create_references(rule[:reference]) if rule[:reference]
      end
    end
    redirect_to bug_path(@bug)
  end

  private

  def bug_params
    params.require(:bug).permit(:summary, rules_attributes: [:connection, :flow, :message, :reference, :metadata, :detection, :class_type, :reference])
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

end