class Escalations::BugsController < ApplicationController
  load_and_authorize_resource class: 'EscalationBug'
  skip_load_resource only: [:index, :show]

  before_action :require_login
  before_action :query_bugs
  before_action :check_bug_permission, only: [:show]
  before_action :get_states_and_users, only: [:index, :show, :new]
  after_action  :sync_summary, only: [:add_tag, :remove_tag]


  def index
    @distinct_gibs = nil
    @tags = Tag.all.map { |tag| tag.name }.join(',')
    @final_giblets = nil
    @giblets = Giblet.all.map { |gib| "#{gib.name}"}.uniq.sort.join(',')


    session[:query] = session[:query].blank? ? current_user.default_bug_list : session[:query]

    if (params[:bug].present? && params[:bug][:tag_names].present?) || params[:tag_names].present?
      tag_names_array = params[:tag_names].present? ? params[:tag_names] : params[:bug][:tag_names]


      distinct_gibs = Giblet.select('distinct name, gib_type').where(:name => tag_names_array )

      @final_giblets = []
      distinct_gibs.each do |dgib|
        @final_giblets << Giblet.where(:name => dgib.name, :gib_type => dgib.gib_type).first
      end


      if !session.has_key? :search
        session[:search] = {}
      end

      session[:search][:giblets] = []
      @final_giblets.each do |gib|
        session[:search][:giblets] << gib.id
      end
      session[:query] = "advance-search"

    end

    if params[:saved_search_id].present?
      saved_search = SavedSearch.where({:id => params[:saved_search_id], :user_id => current_user.id}).first
      if saved_search.present?
        session[:query] = saved_search.session_query
        session[:search] = JSON.parse(saved_search.session_search).symbolize_keys
      end
    end

    if params[:bug].present? && params[:bug][:saved_search].present?
      SavedSearch.create({:user_id => current_user.id, :name => params[:bug][:saved_search], :session_query => session[:query], :session_search => session[:search].to_json, :product => "escalations"})
    end

    @bug_query = Bug.query(current_user, session[:query], session[:search], "escalations")

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
              Bug.by_escalations.where("id BETWEEN ? AND ?", params[:bug][:id], params[:bug][:bugzilla_max]).permit_class_level(current_user.class_level)
                  .paginate(:page => session[:page], :per_page => 32)
          @bug_search_id = '' # otherwise the form will show the lower end of the range
        else
          @bugs =
              Bug.by_escalations.where("id LIKE ?", "%#{params[:bug][:id]}%").permit_class_level(current_user.class_level)
                  .paginate(:page => session[:page], :per_page => 32)
        end
      end
    end

    #if params[:giblet_id].present?
    #  giblet_id = params[:giblet_id]
    #  @giblet = Giblet.where(:id => giblet_id).first

    #  @bugs = @giblet.gib.bugs.permit_class_level(current_user.class_level).paginate(:page => session[:page], :per_page => 32)
    #end




    #testing
    #@bugs = Bug.where(:product => "escalations").paginate(:page => session[:page], :per_page => 32)
  end

  def new
    @bug = current_user.bugs.build(type: 'EscalationBug')
    @tags = Tag.all.map { |tag| tag.name }.join(',')
  end

  def create
    respond_to do |format|
      format.js { head :no_content }
    end
  end

  def show

    @giblets = Giblet.all.map { |gib| "#{gib.name}"}.uniq.sort.join(',')
    @bug = EscalationBug.where(id: params[:id]).first

    if @bug
      @unique_giblets = @bug.giblets.map {|g| g.name}.uniq
      @show_resolve_button = ['NEW', 'OPEN', 'ASSIGNED', 'DUPLICATE', 'REOPENED'].include?(@bug.state)
      @rules = @bug.rules.sort { |left, right| left <=> right }
      @ref_types = ReferenceType.valid_reference_types
      @pcap_attachments = []
      @other_attachments = []
      @bug.attachments.where(is_obsolete: false).map do |att|
        if File.extname(att.file_name.downcase) == ".pcap"
          @pcap_attachments << att
        else
          @other_attachments << att
        end
      end
      @obsolete_attachments = @bug.attachments.where(is_obsolete: true)
      @tasks = @bug.tasks.order(created_at: :desc)
      @notes = @bug.notes.published.order(created_at: :desc) + @bug.notes.error_notes
      @tags = Tag.all.map { |tag| tag.name }.join(',')
      @whiteboards = Whiteboard.all.map { |wb| wb.name }.join(',')
      flash.now[:alert] = "Looks like this bug (#{@bug.id}) may be out of sink with bugzilla.
                       Please 'resink' using the button below." if @bug.bugzilla_synch_needed?
    else
      redirect_to '/escalations/bugs'
      flash[:error] = "Could not find bug #{params[:id]}"
    end
  end

  # TODO find out if this is necessary, or if updates are done via the API.
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

    if @bug.giblets.select {|giblet| giblet.gib == @tag}.blank?
      new_gib = Giblet.create(:bug_id => @bug.id, :gib_type => "Tag", :gib_id => @tag.id)
      new_gib.name = new_gib.display_name
      new_gib.save
    end

    respond_to do |format|
      format.json { head :no_content }
    end
  end

  def remove_tag
    @bug = Bug.find(params[:bug][:id])
    @tag = Tag.find_by(name: params[:bug][:tag_name])
    @bug.tags.destroy(@tag)

    if @bug.giblets.select {|giblet| giblet.gib == @tag}.present?
      gib = @bug.giblets.select {|giblet| giblet.gib == @tag}.first
      @bug.giblets.destroy(gib)
    end

    respond_to do |format|
      format.json { head :no_content }
    end
  end

  def add_whiteboard
    @bug = Bug.find(params[:bug][:id])
    @whiteboard = Whiteboard.find_or_create_by(name: params[:bug][:whiteboard_name].upcase)
    @bug.whiteboards << @whiteboard

    if @bug.giblets.select {|giblet| giblet.gib == @whiteboard}.blank?
      new_gib = Giblet.create(:bug_id => @bug.id, :gib_type => "Whiteboard", :gib_id => @whiteboard.id)
      new_gib.name = new_gib.display_name
      new_gib.save
    end

    respond_to do |format|
      format.json { head :no_content }
    end
  end

  def remove_whiteboard
    @bug = Bug.find(params[:bug][:id])
    @whiteboard = Whiteboard.find_by(name: params[:bug][:whiteboard_name])
    @bug.whiteboards.destroy(@whiteboard)

    if @bug.giblets.select {|giblet| giblet.gib == @whiteboard}.present?
      gib = @bug.giblets.select {|giblet| giblet.gib == @whiteboard}.first
      @bug.giblets.destroy(gib)
    end

    respond_to do |format|
      format.json { head :no_content }
    end
  end



  # def bug_metrics
  #   @bug = Bug.find(params[:bug_id])
  #
  #   respond_to do |format|
  #     format.json {
  #       render :json => [@bug.work_time,
  #                        @bug.rework_time,
  #                        @bug.review_time,
  #                        @bug.resolution_time]
  #     }
  #   end
  # end

  private

  def bug_params
    params.require(:bug).permit(:product, :component, :state, :creator, :opsys, :severity, :platform, :priority, :classification, :searchID,
                                :summary, :whiteboard, :version, :description, :user_id, :committer_id, rules_attributes: [:connection, :flow, :message, :reference,
                                                                                                              :metadata, :detection, :class_type, :reference], tag_names: [])
  end

  def query_params
    params.require(:bug).permit(:id, :bugzilla_max, :summary, :user_id, :committer_id, :state, :whiteboard, :component, :snippet)
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
        redirect_to '/escalations/bugs'
        flash[:error] = "Couldn't find Bug #{params[:id]}"
      when !bug.check_permission(current_user)
        redirect_to '/escalations/bugs'
        flash[:error] = "You dont have permission to access bug: #{params[:id]}"
    end
  end

end
