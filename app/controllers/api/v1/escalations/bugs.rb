module API
  module V1
    module Escalations
      class Bugs < Grape::API
        include API::V1::Defaults

        resource "escalations/bugs" do
          before do
            PaperTrail.request.whodunnit = current_user.id if current_user.present?
          end

          desc "import one bug from bugzilla"
          params do
            requires :id, type: Integer, desc: "Bugzilla id."
            optional :import_type, type: String, desc: "Type of Import"
          end
          get 'import/:id' do
            authorize!(:import, EscalationBug)
            import_type = params[:import_type].present? ? params[:import_type] : "import"
            xmlrpc_token = request.headers['Xmlrpc-Token']

            if xmlrpc_token
              Rails.logger.debug("Bugzilla: Importing Bug: #{params[:id]}")
              progress_bar = Event.create(user: current_user.display_name, action: "import_bug:#{params[:id]}", description: "#{request.headers["Token"]}", progress: 10)

              begin

                ActiveRecord::Base.transaction do
                  xmlrpc = Bugzilla::Bug.new(bugzilla_session)
                  new_bug = xmlrpc.get(permitted_params[:id])
                  initial_bug_state = Bug.where(id: permitted_params[:id]).first
                  if initial_bug_state
                    initial_bug_state = initial_bug_state.clone
                  end
                  progress_bar.update_attribute("progress", 10)
                  #create the bug from bugzilla
                  bug = Bug.bugzilla_import_escalation(current_user, xmlrpc, xmlrpc_token, new_bug, progress_bar, import_type).first
                  if initial_bug_state.present?
                    report = bug.compile_import_report(initial_bug_state)
                  end

                  sleep(1)
                  {:status => "success", :import_report => report}.to_json
                end

              rescue Exception => e
                Rails.logger.error "Bug failed to upload, backing out all DB changes."
                Rails.logger.error $!
                Rails.logger.error $!.backtrace.join("\n")
                progress_bar.update_attribute("progress", -1)
                error = "There was an error when attempting to upload bug, no bug was uploaded or sunk as a result."
                {:error => error}.to_json
              end
            else
              false
            end
          end

          desc "test the websocket"
          get 'websocket' do
            bug = Bug.first
            record = {resource: 'bug',
                      action: 'update',
                      id: bug.id,
                      obj: bug}
            PublishWebsocket.push_changes(record)
          end

          desc "update all tabs"
          params do
            requires :id, type: Integer, desc: "Bugzilla id."
          end
          get '/tabs/:id' do
            begin
              authorize!(:read, EscalationBug)
              bug = Bug.where(:id => params[:id]).includes([:alerts, :pcaps => [:alerts]]).first
              authorize!(:read, bug)

              response = {}


              response.to_json
            rescue
              Rails.logger.error($!)
              Rails.logger.error($!.backtrace.join("\n"))
              response = {}
              response[:status] = "fail"
              response[:error] = "Something went wrong. Tabs were not updated."
              response.to_json
            end
          end

          desc "import all bugs assigned to a user"
          params do
            requires :user_id, type: Integer, desc: "the id of the user whose bugs we want"
          end
          get '/by_user/:user_id' do
            authorize!(:import, EscalationBug)
            xmlrpc_token = request.headers['Xmlrpc-Token']
            user_email = User.where(id: permitted_params[:user_id]).first.email

            if xmlrpc_token && user_email
              begin
                xmlrpc = Bugzilla::Bug.new(bugzilla_session)
                new_bugs = xmlrpc.search(assigned_to: user_email, component: ['Malware', 'SO Rules', 'Snort Rules'])

                #create the bugs from bugzilla
                if new_bugs['bugs'].any?
                  Bug.bugzilla_light_import(new_bugs, xmlrpc, xmlrpc_token,
                                            user_email: user_email, current_user: current_user).to_s
                end
              rescue Exception => e
                Rails.logger.info e
                false
              end
            else
              false
            end
          end


          desc "get latest bugs from bugzilla"
          get 'import_all' do
            authorize!(:import, EscalationBug)
            import_type = params[:import_type].present? ? params[:import_type] : "import"
            xmlrpc_token = request.headers['Xmlrpc-Token']
            if xmlrpc_token
              xmlrpc = Bugzilla::Bug.new(bugzilla_session)
              last_updated = Bug.get_last_import_all()
              new_bugs = xmlrpc.search(last_change_time: last_updated) #then we need to go over all new bugs and import them
              Bug.bugzilla_import(current_user, xmlrpc, xmlrpc_token, new_bugs, import_type)
              "true"
            else
              "false"
            end
          end

          desc "synch bug element"
          params do
            requires :id, type: Integer, desc: "Bugzilla id."
            requires :element, type: String, desc: "element of bug wanting to sync, options are attachments or history"
          end
          get "/synch_bug/:element/:id" do
            authorize!(:import, EscalationBug)
            xmlrpc_token = request.headers['Xmlrpc-Token']
            if xmlrpc_token
              begin
                xmlrpc = Bugzilla::Bug.new(bugzilla_session)
                new_bug = xmlrpc.get(permitted_params[:id])
                if permitted_params[:element] == 'attachments'
                  Bug.synch_attachments(xmlrpc, new_bug, current_user).to_s
                else
                  # history
                  Bug.synch_history(xmlrpc, new_bug).to_s
                end
              end
            else
              false
            end
          end

          desc "search for bugs"
          params do
            optional :summary, type: String, desc: "summary query"
            optional :id_range, type: String, desc: "bugzilla id range may be one value or a range between values"
            optional :state, type: String, desc: "The state of the bug"
            optional :user_id, type: String, desc: "This is a particular user"
            optional :committer, type: String, desc: "searching for a commiter"
          end
          post '/search/' do
            authorize!(:index, EscalationBug)
            terms = {
                :bugzilla_id => /-/.match(permitted_params[:id_range]) ? nil : permitted_params[:id_range],
                :state => permitted_params[:state] ? permitted_params[:state] : nil,
                :user_id => permitted_params[:user_id] ? permitted_params[:user_id] : nil,
                :committer_id => permitted_params[:committer] ? permitted_params[:committer] : nil
            }.reject { |k, v| v.blank? }
            range = {
                :gte => /-/.match(permitted_params[:id_range]) ? /(\d+)-/.match(permitted_params[:id_range])[1] : nil,
                :lte => /-/.match(permitted_params[:id_range]) ? /-(\d+)/.match(permitted_params[:id_range])[1] : nil,
            }.reject { |k, v| v.blank? }

            # search bugs and return the bugs current user is allowed to see
            hits = []
            Bug.search(permitted_params[:summary], terms, range).each do |bug_hit|
              authorize!(:read, bug_hit)
              hits << bug_hit.id if bug_hit.check_permission(current_user)
            end
            hits
          end

          desc "get a single bug"
          params do
            requires :id, type: String, desc: "ID of the bug"
          end
          get ':id' do
            authorize!(:read, EscalationBug)
            # Bug.where(id: permitted_params[:id]).page(params[:page]).per(params[:per_page]).where("classification <= ?", User.class_levels[current_user.class_level])
            bug = Bug.where(id: permitted_params[:id])
            authorize!(:read, bug)
          end

          desc "get all bugs"
          params do
            use :pagination
          end
          get "", root: :bugs do
            authorize!(:read, EscalationBug)
            bugs = Bug.all.where("classification <= ?", User.class_levels[current_user.class_level]).page(params[:page]).per(params[:per_page])
            bugs.each do |bug|
              authorize!(:read, bug)
            end
            render bugs, {meta: {total_pages: bugs.total_pages}}
          end

          desc "update a bug"
          params do
            requires :id, type: Integer, desc: "The id of the bug to be updated."
            requires :bug, type: Hash do
              optional :whiteboard, type: String, desc: "Whiteboard field from Bugzilla"
              optional :user_id, type: Integer, desc: "the user this bug is assigned to"
              optional :product, type: String, desc: "The name of the product the bug is being filed against."
              optional :component, type: String, desc: "The name of a component in the product above."
              optional :summary, type: String, desc: "A brief description of the bug being filed."
              optional :version, type: String, desc: "A version of the product above; the version the bug was found in."
              optional :description, type: String, desc: "A full text description of the bug"
              optional :state, type: String, desc: "The state of the bug, Open, Closed, ReOpened,etc"
              optional :state_comment, type: String, desc: "When changing the state there should be a comment about changing it."
              optional :state_id, type: String, desc: "The new state of the bug, Open, Closed, ReOpened,etc"
              optional :creator, type: String, desc: "The person who created the bug"
              optional :opsys, type: String, desc: "The operating system that this bug affects"
              optional :platform, type: String, desc: "What platform this bug runs on"
              optional :priority, type: String, desc: "How soon should this bug get fixed"
              optional :severity, type: String, desc: "How terrible is this bug"
              optional :classification, type: String, desc: "Who should see this bug. Higher classification restricts more people from seeing it."
              optional :new_research_notes, type: String, desc: "Current working draft of research notes"
              optional :new_committer_notes, type: String, desc: "Current working draft of committer notes"
              optional :editor_id, type: String, desc: "id of the new user to be assigned to the bug"
              optional :committer_id, type: String, desc: "id of the new committer to be assigned to the bug"
              optional :tag_names, type: Array, desc: "array of tag names"
            end

          end
          put ":id", root: "bug" do
            authorize!(:update, EscalationBug)
            ActiveRecord::Base.transaction do
              bug = Bug.find(permitted_params[:id])
              authorize!(:update, bug)
              # Bug.process_bug_update(current_user, bugzilla_session, bug, permitted_params)
              bug.update_bug_action(current_user: current_user,
                                    bugzilla_session: bugzilla_session,
                                    assignee_id: permitted_params[:bug][:user_id],
                                    committer_id: permitted_params[:bug][:committer_id],
                                    permitted_params: permitted_params)
            end
          end

          desc "create a bug"
          params do
            requires :bug, type: Hash do
              requires :product, type: String, desc: "The name of the product the bug is being filed against."
              requires :component, type: String, desc: "The name of a component in the product above."
              requires :summary, type: String, desc: "A brief description of the bug being filed."
              requires :version, type: String, desc: "A version of the product above; the version the bug was found in."
              requires :description, type: String, desc: "A full text description of the bug"
              optional :state, type: String, desc: "The state of the bug, Open, Closed, ReOpened,etc"
              optional :creator, type: String, desc: "The person who created the bug"
              optional :opsys, type: String, desc: "The operating system that this bug affects"
              optional :platform, type: String, desc: "What platform this bug runs on"
              optional :priority, type: String, desc: "How soon should this bug get fixed"
              optional :severity, type: String, desc: "How terrible is this bug"
              optional :classification, type: String, desc: "Who should see this bug. Higher classification restricts more people from seeing it."
            end
          end
          post "", root: "bug" do
            authorize!(:create, EscalationBug)
            bug = Bug.bugzilla_create_escalation_action(bugzilla_session, permitted_params[:bug], user: current_user)
            authorize!(:create, bug)
          end

          desc "remove a bug from the db only"
          params do
            requires :id, type: Integer, desc: "Bugzilla id."
          end
          delete ":id", root: "bug" do
            begin
              authorize!(:destroy, EscalationBug)
              bug = EscalationBug.where(id: permitted_params[:id])
              authorize!(:destroy, bug)
              bug.destroy
            rescue CanCan::AccessDenied => e
              error!({error: "Access denied.", message: e.message}, 200)
            end
          end

          desc "close a bug"
          params do
            requires :id, type: String, desc: "id of the bug"
            requires :notes, type: String, desc: "notes about closing a bug"
            # all the params we need to permit must to go here
          end
          post "close/:id", root: "bug" do
            authorize!(:update, EscalationBug)
            xmlrpc_token = request.headers['Xmlrpc-Token']
            if xmlrpc_token
              bug = Bug.where(id: permitted_params[:id])
              authorize!(:update, bug)
              status = "resolved"
              resolution = "Fixed"
              return bug.bug_state(bugzilla_session, permitted_params[:notes], status, resolution)
            else
              false
            end
          end

          desc "wontfix a bug"
          params do
            requires :id, type: String, desc: "id of the bug"
            requires :notes, type: String, desc: "notes about closing a bug"
            # all the params we need to permit must to go here
          end
          post "wontfix/:id", root: "bug" do
            authorize!(:update, EscalationBug)
            xmlrpc_token = request.headers['Xmlrpc-Token']
            if xmlrpc_token
              bug = Bug.where(id: permitted_params[:id])
              authorize!(:update, bug)
              status = "resolved"
              resolution = "WontFix"
              return bug.bug_state(bugzilla_session, permitted_params[:notes], status, resolution)
            else
              false
            end
          end

          desc "reopen a bug"
          params do
            requires :id, type: String, desc: "id of the bug"
            requires :notes, type: String, desc: "notes about closing a bug"
            # all the params we need to permit must to go here
          end
          post "reopen/:id", root: "bug" do
            authorize!(:update, EscalationBug)
            xmlrpc_token = request.headers['Xmlrpc-Token']
            if xmlrpc_token
              bug = Bug.where(id: permitted_params[:id])
              authorize!(:update, bug)
              status = "reopened"
              resolution = "reopened"
              return bug.bug_state(bugzilla_session, permitted_params[:notes], status, resolution)
            else
              false
            end
          end

          desc "subscribe to a bug"
          params do
            requires :id, type: String, desc: "id of the bug"
            requires :committer, type: Boolean, desc: "is this a committer subscribe"
          end
          post ':id/subscribe' do
            authorize!(:read, EscalationBug)
            bug = Bug.where(id: permitted_params[:id]).where("classification <= ?", User.class_levels[current_user.class_level]).first
            authorize!(:read, bug)
            unless bug.nil?
              begin
                if params[:committer]
                  if bug.committer == current_user
                    return {error: 'already subscribed to this bug'}
                  else
                    options = Rails.env.development? ? {:ids => permitted_params[:id], :qa_contact => Rails.configuration.backend_auth[:authenticate_email]} : {:ids => permitted_params[:id], :qa_contact => current_user.email}
                    Bugzilla::Bug.new(bugzilla_session).update(options.to_h)
                    Bug.update(permitted_params[:id], committer_id: current_user.id)
                  end
                else
                  if current_user.bugs.exists?(bug.id)
                    return {error: 'already subscribed to this bug'}
                  else
                    options = Rails.env.development? ? {:ids => permitted_params[:id], :assigned_to => Rails.configuration.backend_auth[:authenticate_email]} : {:ids => permitted_params[:id], :assigned_to => current_user.email}
                    Bugzilla::Bug.new(bugzilla_session).update(options.to_h)
                    current_user.bugs << bug
                    Bug.update(permitted_params[:id], state: "ASSIGNED") unless ['PENDING', 'FIXED', 'WONTFIX', 'INVALID', 'LATER'].include? bug.state
                  end
                end
                return true
              rescue XMLRPC::FaultException => e
                throw :error,
                      status: 400,
                      message: "#{e.message}"
              end
            end
            throw :error,
                  status: 404,
                  message: 'cannot find bug to subscribe'
          end


          desc "unsubscribe to a bug"
          params do
            requires :id, type: String, desc: "id of the bug"
            requires :committer, type: Boolean, desc: "is this a committer subscribe"
          end
          post ':id/unsubscribe' do
            # TODO Determine access control policy for unsubscribing from a bug
            bug = current_user.bugs.where(id: permitted_params[:id])
            unless bug.nil?
              begin
                if params[:committer]
                  vrt_qa = User.where(email: "vrt-qa@sourcefire.com").first
                  options = {:ids => permitted_params[:id], :qa_contact => "vrt-qa@sourcefire.com"}
                  Bugzilla::Bug.new(bugzilla_session).update(options.to_h)
                  Bug.update(permitted_params[:id], committer_id: vrt_qa.id)
                else
                  vrt_incoming = User.where(email: "vrt-incoming@sourcefire.com").first
                  options = {:ids => permitted_params[:id], :reset_assigned_to => true, :assigned_to => "vrt-incoming@sourcefire.com"}
                  Bugzilla::Bug.new(bugzilla_session).update(options.to_h)
                  current_user.bugs.delete(bug)
                  Bug.update(permitted_params[:id], state: "NEW")
                  vrt_incoming.bugs << bug
                end
                return true
              rescue XMLRPC::FaultException => e
                throw :error,
                      status: 400,
                      message: e.message
              end
            end
            throw :error,
                  status: 404,
                  message: 'cannot find bug to unsubscribe'
          end

          desc "add a reference to a bug"
          params do
            requires :bug_id, type: Integer, desc: "bugzilla id of the bug"
          end
          post ':bug_id/addref' do
            authorize!(:create, Reference)
            bug = Bug.where(id: params['bug_id']).first
            authorize!(:update, bug)
            raise 'bug not found' unless bug
            new_ref = bug.add_ref_action(ref_type_name: params['ref_type_name'], ref_data: params['ref_data'])
            if new_ref.present?
              if bug.giblets.select {|giblet| giblet.gib == new_ref}.blank?
                if new_ref.reference_type.name != "url"
                  new_gib = Giblet.create(:bug_id => bug.id, :gib_type => "Reference", :gib_id => new_ref.id)
                  new_gib.name = new_gib.display_name
                  new_gib.save
                else
                  if new_ref.reference_data.include?("microsoft.com")
                    msb_val = new_ref.reference_data.split('/').last.split('.').first.upcase
                    ref_type = ReferenceType.where(:name => 'msb').first
                    alt_ref = Reference.find_or_create_by(:reference_type_id => ref_type.id, :reference_data => msb_val)
                    bug.references << alt_ref unless bug.references.include?(alt_ref)
                    new_gib = Giblet.create(:bug_id => bug.id, :gib_type => "Reference", :gib_id => alt_ref.id)
                    new_gib.name = new_gib.display_name
                    new_gib.save
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
