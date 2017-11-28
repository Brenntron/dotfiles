module API
  module V1
    class Bugs < Grape::API
      include API::V1::Defaults

      resource :bugs do
        before do
          PaperTrail.whodunnit = current_user.id if current_user.present?
        end

        desc "import one bug from bugzilla"
        params do
          requires :id, type: Integer, desc: "Bugzilla id."
          optional :import_type, type: String, desc: "Type of Import"
        end
        get 'import/:id' do
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
                bug = Bug.bugzilla_import(current_user, xmlrpc, xmlrpc_token, new_bug, progress_bar, import_type).first

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
            bug = Bug.where(:id => params[:id]).includes([:alerts, :pcaps => [:alerts]]).first

            response = {}
            response[:status] = "success"
            response[:attachments_tab] = []
            response[:alerts_tab] = {}
            response[:alerts_tab][:alerts] = []

            rules = bug.rules.sort { |left, right| left <=> right }
            pcap_attachments = []
            bug.attachments.where(is_obsolete: false).map do |att|
              if File.extname(att.file_name.downcase) == ".pcap"
                pcap_attachments << att
              end
            end

            pcap_attachments.each do |att|
              alert = {}
              alert[:direct_upload_url] = att.direct_upload_url
              alert[:file_name] = att.file_name
              alert[:rules] = []
              alert[:pcap_alerts] = []
              rules.each do |rule|
                has_untested_attachments = att.bug.bugs_rules.select{|b| b.rule_id == rule.id && b.tested == true }.blank?
                has_local_alerts = att.alerts.select {|alert| alert.test_group == Alert::TEST_GROUP_LOCAL && alert.rule_id == rule.id}.present?
                pcap_rule = {}
                pcap_rule[:alert_css_class] = Rule.get_alert_css_class_for(has_untested_attachments, has_local_alerts)
                pcap_rule[:alert_status] = Rule.get_alert_status_for(has_untested_attachments, has_local_alerts)
                pcap_rule[:sid_colon_format] = rule.sid_colon_format
                pcap_rule[:message] = rule.message
                alert[:rules] << pcap_rule
              end

              pc_alert = {}
              pc_alert[:id] = att.id
              pc_alert[:alert_count] = att.alerts.select{|alert| alert.test_group == Alert::TEST_GROUP_PCAP}.size


              pc_alert[:pcap_alerts] = []

              att.pcap_alerts.includes(:rule).where.not(rules: {sid: nil}).order('rules.gid, rules.sid').each do |p_alert|
                new_pcap_alert = {}
                new_pcap_alert[:sid_colon_format] = p_alert.rule.sid_colon_format
                new_pcap_alert[:message] = p_alert.rule.message
                new_pcap_alert[:rule_id] = p_alert.rule.id
                alert[:pcap_alerts] << new_pcap_alert
                pc_alert[:pcap_alerts] << new_pcap_alert
              end
              response[:alerts_tab][:alerts] << alert
              response[:attachments_tab] << pc_alert
            end


            response[:rules_tab] = []

            rules.each do |rule|
              rule_packet = {}
              rule_packet[:id] = rule.id

              if rule.tested_on_bug?(bug)
                rule_packet[:tested] = true
                rule_packet[:svn_output] = rule.svn_result_output
              else
                rule_packet[:tested] = false
                rule_packet[:svn_output] = ""
              end

              rule_packet[:alert_count] = rule.display_alerts_count(bug)
              rule_packet[:alerts] = rule.display_alerts(bug)

              response[:rules_tab] << rule_packet
            end

            response[:jobs_tab] = []
            bug_queue = []

            tasks = bug.tasks.any_relations.reverse_chron
            jobs_open = 0
            tasks.each do |task|
              task.check_timeout
              task.reload
              jobs_open += 1 if !task.completed
              response_task = {}
              response_task['id'] = task.id
              response_task['rule_list'] = task.task_type == Task::TASK_TYPE_LOCAL_TEST ? task.rules.map { |rule| rule.new_rule? ? 'new-rule' : "#{rule.gid}:#{rule.sid}:#{rule.rev}" }.join('; ') : ""
              response_task['completed'] = task.completed
              response_task['failed'] = task.failed
              response_task['cvs_username'] = User.find(task.user_id).cvs_username
              response_task['task_type'] = task.task_type
              response_task['result'] = task.result.present? ? task.result : "Please wait while task completes."
              response_task['created_at'] = task.created_at.in_time_zone("Eastern Time (US & Canada)").strftime("%m/%d/%y %H:%M:%S") #TODO change in_time_zone to reflect the users timezone.(when we have configurations for this stuff)
              bug_queue << response_task
            end
            response[:jobs_tab] = bug_queue
            response[:open_jobs_count] = jobs_open

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


        desc "delete a rule with this bug"
        params do
          requires :link, type: String, desc: "bug:bug_id&rule:rule_id"
        end
        delete '/rules/:link' do
          Bug.where(id: permitted_params[:link].split(':')[0]).first.rules.destroy(permitted_params[:link].split(':')[1]).first
        end

        desc "unlink a rule with this bug"
        params do
          requires :bugzilla_id, type: Integer, desc: "bugzilla id of the bug"
          requires :rule_ids, type: Array[Integer]
        end
        delete '/:bugzilla_id/rules/unlink' do
          Bug.unlink_action(permitted_params[:bugzilla_id], permitted_params[:rule_ids])
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
            hits << bug_hit.id if bug_hit.check_permission(current_user)
          end
          hits
        end

        desc "link a rule to this bug"
        params do
          requires :bug_id, type: Integer, desc: "bugzilla id of the bug"
          requires :gid, type: Integer, desc: "gid of the rule"
          requires :sid, type: Integer, desc: "sid of the rule"
        end
        post ':bug_id/rules/:gid~:sid/link' do
          Bug.link_action(permitted_params[:bug_id], permitted_params[:sid], permitted_params[:gid])
        end

        desc "link all alerting rules to this bug"
        params do
          requires :bugzilla_id, type: String, desc: "The bug associated with the task"
          requires :attachment_array, type: Array[String], desc: "The attachments to test. this is a list of bugzilla attachment id's"
        end
        post 'attachments/link_rules' do
          Bug.link_alerts_action(permitted_params[:bugzilla_id], permitted_params[:attachment_array])
        end

        desc "get a single bug"
        params do
          requires :id, type: String, desc: "ID of the bug"
        end
        get ':id' do
          # Bug.where(id: permitted_params[:id]).page(params[:page]).per(params[:per_page]).where("classification <= ?", User.class_levels[current_user.class_level])
          Bug.where(id: permitted_params[:id])
        end

        desc "get all bugs"
        params do
          use :pagination
        end
        get "", root: :bugs do
          bugs = Bug.all.where("classification <= ?", User.class_levels[current_user.class_level]).page(params[:page]).per(params[:per_page])
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
          ActiveRecord::Base.transaction do
            bug = Bug.find(permitted_params[:id])
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
          authorize! :create, Bug
          options = {
              :product => permitted_params[:bug][:product],
              :component => permitted_params[:bug][:component],
              :summary => permitted_params[:bug][:summary],
              :version => permitted_params[:bug][:version],
              :description => permitted_params[:bug][:description],
              :state => permitted_params[:bug][:state],
              :creator => permitted_params[:bug][:creator],
              :opsys => permitted_params[:bug][:opsys],
              :platform => permitted_params[:bug][:platform],
              :priority => permitted_params[:bug][:priority],
              :severity => permitted_params[:bug][:severity],
              :classification => permitted_params[:bug][:classification],
              :assigned_to => current_user.email
          }.reject() { |k, v| v.nil? } #remove any nil or empty values in the hash(bugzilla doesnt like them)

          xmlrpc = Bugzilla::Bug.new(bugzilla_session)
          new_bug = xmlrpc.create(options.to_h) #the bugzilla session is where we authenticate

          new_bug_id = new_bug["id"]
          bug = Bug.create!(
              :id => new_bug_id,
              :bugzilla_id => new_bug_id,
              :product => permitted_params[:bug][:product],
              :component => permitted_params[:bug][:component],
              :summary => permitted_params[:bug][:summary],
              :version => permitted_params[:bug][:version],
              :description => permitted_params[:bug][:description],
              :state => permitted_params[:bug][:state] || 'OPEN',
              :creator => permitted_params[:bug][:creator],
              :opsys => permitted_params[:bug][:opsys],
              :platform => permitted_params[:bug][:platform],
              :priority => permitted_params[:bug][:priority],
              :severity => permitted_params[:bug][:severity],
              :classification => permitted_params[:bug][:classification],
              :user_id => current_user.id
          )

          # pull in the first comment
          new_bug_history = xmlrpc.get(new_bug_id)
          Bug.synch_history(xmlrpc, new_bug_history).to_s

          tags = params[:bug][:tag_names]
          if tags
            tags.each do |tag|
              new_tag = Tag.find_or_create_by(name: tag)
              bug.tags << new_tag
            end
          end
          # update the summary (regarding tags)
          bug.compose_summary
          return bug
        end

        desc "remove a bug from the db only"
        params do
          requires :id, type: Integer, desc: "Bugzilla id."
        end
        delete ":id", root: "bug" do
          begin
            authorize! :destroy, Bug
            Bug.destroy(permitted_params[:id])
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
          xmlrpc_token = request.headers['Xmlrpc-Token']
          if xmlrpc_token
            bug = Bug.where(id: permitted_params[:id])
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
          xmlrpc_token = request.headers['Xmlrpc-Token']
          if xmlrpc_token
            bug = Bug.where(id: permitted_params[:id])
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
          xmlrpc_token = request.headers['Xmlrpc-Token']
          if xmlrpc_token
            bug = Bug.where(id: permitted_params[:id])
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
          bug = Bug.where(id: permitted_params[:id]).where("classification <= ?", User.class_levels[current_user.class_level]).first
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
          bug = Bug.where(id: params['bug_id']).first
          raise 'bug not found' unless bug
          bug.add_ref_action(ref_type_name: params['ref_type_name'], ref_data: params['ref_data'])
        end

        desc "add an exploit to a bug"
        params do
          requires :bug_id, type: Integer, desc: "bugzilla id of the bug"
        end
        post ':bug_id/addexploit' do
          bug = Bug.where(id: params['bug_id']).first
          raise 'bug not found' unless bug
          bug.add_exploit_action(reference_id: params['reference_id'],
                                 exploit_type_id: params['exploit_type_id'],
                                 attachment_id: params['attachment_id'],
                                 exploit_data: params['exploit_data'])
        end

        params do
          requires :bug_id, type: Integer, desc: "bugzilla id of the bug"
        end
        patch ':bug_id/toggle_liberty' do
          bug = Bug.where(id: params['bug_id']).first
          raise 'bug not found' unless bug
          authorize!(:toggle_liberty, bug)
          bug.toggle_liberty
        end
      end
    end
  end
end
