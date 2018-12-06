module API
  module V1
    class Bugs < Grape::API
      include API::V1::Defaults

      resource :bugs do
        before do
          PaperTrail.request.whodunnit = current_user.id if current_user.present?
        end

        desc "import one bug from bugzilla"
        params do
          requires :id, type: Integer, desc: "Bugzilla id."
          optional :import_type, type: String, desc: "Type of Import"
        end
        get 'import/:id' do
          authorize!(:import, ResearchBug)
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
            authorize!(:read, ResearchBug)
            bug = Bug.where(:id => params[:id]).includes([:alerts, :pcaps => [:alerts]]).first
            authorize!(:read, bug)

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
          authorize!(:import, ResearchBug)
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
          authorize!(:import, ResearchBug)
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
          authorize!(:import, ResearchBug)
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


        # TODO Move to rule API
        desc "delete a rule with this bug"
        params do
          requires :link, type: String, desc: "bug:bug_id&rule:rule_id"
        end
        delete '/rules/:link' do
          bug = Bug.where(id: permitted_params[:link].split(':')[0]).first
          rule = bug.rules.where(id: permitted_params[:link].split(':')[1]).first
          authorize!(:destroy, rule)
          rule.destroy
        end

        desc "unlink a rule with this bug"
        params do
          requires :bugzilla_id, type: Integer, desc: "bugzilla id of the bug"
          requires :rule_ids, type: Array[Integer]
        end
        delete '/:bugzilla_id/rules/unlink' do
          authorize!(:update, ResearchBug)
          bug = ResearchBug.find(permitted_params[:bugzilla_id])
          authorize!(:update, bug)
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
          authorize!(:index, ResearchBug)
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

        desc "link a rule to this bug"
        params do
          requires :bug_id, type: Integer, desc: "bugzilla id of the bug"
          requires :gid, type: Integer, desc: "gid of the rule"
          requires :sid, type: Integer, desc: "sid of the rule"
        end
        post ':bug_id/rules/:gid~:sid/link' do
          authorize!(:update, ResearchBug)
          bug = ResearchBug.find(permitted_params[:bug_id])
          authorize!(:update, bug)
          Bug.link_action(permitted_params[:bug_id], permitted_params[:sid], permitted_params[:gid])
        end

        desc "link all alerting rules to this bug"
        params do
          requires :bugzilla_id, type: String, desc: "The bug associated with the task"
          requires :attachment_array, type: Array[String], desc: "The attachments to test. this is a list of bugzilla attachment id's"
        end
        post 'attachments/link_rules' do
          authorize!(:update, ResearchBug)
          bug = ResearchBug.find(permitted_params[:bugzilla_id])
          authorize!(:update, bug)
          Bug.link_alerts_action(permitted_params[:bugzilla_id], permitted_params[:attachment_array])
        end

        desc "get a single bug"
        params do
          requires :id, type: String, desc: "ID of the bug"
        end
        get ':id' do
          authorize!(:read, ResearchBug)
          # Bug.where(id: permitted_params[:id]).page(params[:page]).per(params[:per_page]).where("classification <= ?", User.class_levels[current_user.class_level])
          bug = Bug.where(id: permitted_params[:id])
          authorize!(:read, bug)
        end

        desc "get all bugs"
        params do
          use :pagination
        end
        get "", root: :bugs do
          authorize!(:index, ResearchBug)
          bugs = Bug.all.where("classification <= ?", User.class_levels[current_user.class_level]).page(params[:page]).per(params[:per_page])
          bugs.each do |bug|
            authorize!(:read, bug)
          end
          render bugs, {meta: {total_pages: bugs.total_pages}}
        end

        desc "update a bug"
        params do
          requires :id, type: Integer, desc: "The id of the bug to be updated."
          optional :escalation, type: Hash do
            optional :message, type: String, desc: "message for escalation"
            optional :state, type: String, desc: "state of the escalation bug"
          end
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
          authorize!(:update, ResearchBug)
          ActiveRecord::Base.transaction do
            bug = Bug.find(permitted_params[:id])
            authorize!(:update, bug)
            # Bug.process_bug_update(current_user, bugzilla_session, bug, permitted_params)

            bug.update_bug_action(current_user: current_user,
                                  bugzilla_session: bugzilla_session,
                                  assignee_id: permitted_params[:bug][:user_id],
                                  committer_id: permitted_params[:bug][:committer_id],
                                  permitted_params: permitted_params,
                                  new_escalation_message: permitted_params[:escalation].nil? ? "" : permitted_params[:escalation][:message] ,
                                  new_escalation_state:   permitted_params[:escalation].nil? ? "" : permitted_params[:escalation][:state] )
          end
        end

        desc "create a reasearch bug"
        params do
          requires :research_bug, type: Hash do
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
        post "research", root: "bug" do
          authorize! :create, ResearchBug
          unless 'Research' == permitted_params[:research_bug][:product]
            error!('This API entry point is only for research bugs.', 400)
          end

          ResearchBug.bugzilla_create_action(bugzilla_session, permitted_params[:research_bug], user: current_user)
        end

        # TODO move to escalation API
        desc "create an escalation bug"
        params do
          requires :escalation_bug, type: Hash do
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
        post "escalation", root: "bug" do
          authorize! :create, EscalationBug
          unless 'Escalations' == permitted_params[:escalation_bug][:product]
            error!('This API entry point is only for escalation bugs.', 400)
          end

          user = User.where(email: "vrt-incoming@sourcefire.com").first
          EscalationBug.bugzilla_create_action(bugzilla_session, permitted_params[:escalation_bug], user: user)
        end

        desc "remove a bug from the db only"
        params do
          requires :id, type: Integer, desc: "Bugzilla id."
        end
        delete ":id", root: "bug" do
          begin
            authorize!(:destroy, ResearchBug)
            bug = ResearchBug.find(permitted_params[:id])
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
          authorize!(:update, ResearchBug)
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
          authorize!(:update, ResearchBug)
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
          authorize!(:update, ResearchBug)
          xmlrpc_token = request.headers['Xmlrpc-Token']
          if xmlrpc_token
            bug = Bug.where(id: permitted_params[:id]).first
            authorize!(:update, bug)
            status = "REOPENED"
            resolution = "REOPENED"
            return bug.bug_state(bugzilla_session, permitted_params[:notes], status, resolution)
          else
            false
          end
        end




        # TODO If this is from escalations, should it be in the escalations API?
        desc "reopen bugs from escalations"

        post "/reopen_bugs" do
          authorize!(:update, ResearchBug)
          source_bug = Bug.find(params[:id])
          ids_to_reopen = params[:ids]
          comment_when_reopening = params[:comment]
          if comment_when_reopening.blank?
            return {:error => "Need a comment to reopen a bug"}.to_json
          end
          if ids_to_reopen.blank?
            return {:error => "Need a bug id to reopen a bug"}.to_json
          end

          bugs = Bug.where(:id => ids_to_reopen)
          bugs.each do |bug|
            authorize!(:update, bug)
            source_bug.snort_blocker_bugs << bug
          end
          xmlrpc_token = request.headers['Xmlrpc-Token']
          if xmlrpc_token
            qa_contact = User.where(email: "vrt-qa@sourcefire.com").first
            vrt_incoming = User.where(email: "vrt-incoming@sourcefire.com").first
            bugs.each do |bug|

              status = "REOPENED"
              resolution = "REOPENED"

              options = {ids: [bug.id],
                         status: status,
                         resolution: resolution,
                         qa_contact: qa_contact.email,
                         assigned_to: vrt_incoming.email,
                         comment: {body: comment_when_reopening} }

              bug.update_bugzilla_attributes(bugzilla_session, options)

              bug.status = status
              bug.state = resolution
              bug.resolution = resolution
              bug.committer_id = qa_contact.id
              bug.user_id = vrt_incoming.id

              bug.save

              xmlrpc = Bugzilla::Bug.new(bugzilla_session)
              reopened_bugzilla_bug = xmlrpc.get(bug.id)

              reopened_bugzilla_bug['bugs'].each do |item|
                bug_id = item['id']
                new_comments = xmlrpc.comments(ids: [bug_id])
                if new_comments.any?
                  ActiveRecord::Base.transaction do
                    new_comments['bugs'].each do |comment|
                      bug_id = comment[0].to_i
                      comment[1]['comments'].each do |c|
                        if c['text'].downcase.strip.start_with?('commit')
                          note_type = 'committer'
                        elsif c['text'].start_with?('Created attachment')
                          note_type = 'attachment'
                        else
                          note_type = 'research'
                        end
                        comment = c['text'].strip

                        creation_time = c['creation_time'].to_time

                        note = Note.where(id: c['id']).first

                        if note.present?
                          comment = "bugzilla comment is blank" if comment.blank?
                          note.update_attributes(author: c['author'],
                                                 comment: comment,
                                                 bug_id: bug_id,
                                                 note_type: note_type,
                                                 notes_bugzilla_id: c['id'],
                                                 created_at: creation_time)

                        else
                          comment = "bugzilla comment is blank" if comment.blank?
                          Note.create(id: c['id'],
                                      author: c['author'],
                                      comment: comment,
                                      bug_id: bug_id,
                                      note_type: note_type,
                                      created_at: creation_time,
                                      notes_bugzilla_id: c['id']                     )

                        end
                      end
                    end
                  end
                end
              end

            end

            urls_to_open = []
            bugs.each do |bug|
              urls_to_open << "/bugs/#{bug.id}"
            end
            return {:success => true, :urls_to_open => urls_to_open}.to_json

          else
            false
          end

        end

        desc "duplicate/convert a bug from escalation to research"
        params do
          requires :id, type: Integer, desc: "id of escalation to base duplication on"
          requires :summary, type: String, desc: "required new summary line to define research bug."
          requires :description, type: String, desc: "required description of new bug"
        end
        post "/duplicate_bug" do
          authorize!(:create, ResearchBug)


          if params[:id].blank?
            return {:error => "must provide escalation id to convert to research bug."}.to_json
          end
          if params[:summary].blank?
            return {:error => "must provide a new summary line for the new research bug."}.to_json
          end
          if params[:description].blank?
            return {:error => "must provide a description for the new research bug."}.to_json
          end

          escalation_bug = Bug.by_escalations.where(id: params[:id]).first
          return {:error => "Cannot find escalation bug #{params[:id]}."}.to_json unless escalation_bug


          new_summary_line = params[:summary]

          if new_summary_line == escalation_bug.summary
            return {:error => "New research bug summary cannot be the same as its escalation bug."}.to_json
          end
          args = {}
          args[:research_summary] = new_summary_line
          args[:research_notes] = params[:research_notes]
          args[:bugzilla_session] = bugzilla_session
          args[:description] = params[:description]

          new_research_bug = escalation_bug.convert_escalation_to_research(args, current_user: current_user)



          escalation_bug.snort_research_bugs << new_research_bug
          escalation_bug.snort_blocker_bugs << new_research_bug

          research_bug_url = "/bugs/#{new_research_bug.id}"

          {:success => true, :callback_url => research_bug_url}.to_json
          
        end

        desc "subscribe to a bug"
        params do
          requires :id, type: String, desc: "id of the bug"
          requires :committer, type: Boolean, desc: "is this a committer subscribe"
        end
        post ':id/subscribe' do
          authorize!(:read, ResearchBug)
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
                  if request.env['REMOTE_USER']
                    options = {:ids => permitted_params[:id], :assigned_to => current_user.email}
                  else
                    options = Rails.env.development? ? {:ids => permitted_params[:id], :assigned_to => Rails.configuration.backend_auth[:authenticate_email]} : {:ids => permitted_params[:id], :assigned_to => current_user.email}
                  end
                  Bugzilla::Bug.new(bugzilla_session).update(options.to_h)
                  current_user.bugs << bug
                  Bug.update(permitted_params[:id], state: "ASSIGNED") if ['NEW', 'OPEN'].include? bug.state
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

        desc "add an exploit to a bug"
        params do
          requires :bug_id, type: Integer, desc: "bugzilla id of the bug"
        end
        post ':bug_id/addexploit' do
          authorize!(:create, Exploit)
          bug = Bug.where(id: params['bug_id']).first
          authorize!(:update, bug)
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
          authorize!(:toggle_liberty, ResearchBug)
          bug = Bug.where(id: params['bug_id']).first
          raise 'bug not found' unless bug
          authorize!(:toggle_liberty, bug)
          bug.toggle_liberty
        end



        desc "set security of bug"
        params do
          requires :bug_id, type: Integer, desc: "bugzilla id of the bug"
          requires :snort_secure, type: String, desc: "Value to set security to"
        end
        post "set_snort_security/:bug_id" do
          snort_secure = params[:snort_secure]
          begin
            authorize!(:update, ResearchBug)
            ActiveRecord::Base.transaction do
              bug = Bug.find(params[:bug_id])
              authorize!(:update, bug)
              bug.snort_secure = params[:snort_secure]
              bug.save

              xmlrpc = Bugzilla::Bug.new(bugzilla_session)

              options = {}
              options[:ids] = params[:bug_id]
              if bug.snort_secure
                options[:groups] = {:add => ["Restriction:VRT Security Bugs"]}
              else
                options[:groups] = {:remove => ["Restriction:VRT Security Bugs"]}
              end
              xmlrpc.update(options.to_h)
              {:status => "success"}.to_json
            end
          rescue
            {:status => "error", :message => "there was an error in setting the security flag"}.to_json
          end
        end




        desc "list bugs by SID"
        params do
          requires :sid, type: Integer, desc: "sid to search by"
        end
        get 'find_bugs_by_sid/:sid' do
          authorize!(:index, ResearchBug)
          response = {}
          rule = Rule.where(sid: params['sid']).first
          if rule.blank?
            response[:status] = "error"
            response[:message] = "No rule with this sid found"
          else
            response[:status] = "success"
            response[:data] = []
            rule.bugs.each do |bug|
              authorize!(:read, ResearchBug)
              bug_data = {}
              bug_data[:id] = bug.id
              bug_data[:summary] = bug.summary
              response[:data] << bug_data
            end

            response.to_json
          end
        end










        desc "associate a bug"
        params do
          requires :bug_id, type: Integer, desc: "bugzilla id of the bug"
          requires :relate_id, type: Integer, desc: "bugzilla id to relate to bug_id"
        end
        post 'relate_bug/:bug_id/:relate_id' do
          authorize!(:create, EscalationLink)
          bug = Bug.where(id: params['bug_id']).first
          return {:error => 'bug not found'}.to_json unless bug
          authorize!(:update, bug)
          related_bug = Bug.where(id: params['relate_id']).first
          return {:error => 'related bug not found'}.to_json unless related_bug
          if bug.id == related_bug.id
            return {:error => "cannot relate a bug to itself"}.to_json
          end
          if bug.product == "Escalations" && related_bug.product == "Escalations"
            return {:error => 'cannot relate an escalation to another escalation'}.to_json
          end
          if bug.product == "Research" && related_bug.product == "Escalations"
            bug.snort_escalation_bugs << related_bug  unless bug.snort_escalation_bugs.include? related_bug
          end
          if bug.product == "Escalations" && related_bug.product == "Research"
            bug.snort_research_bugs << related_bug  unless bug.snort_research_bugs.include? related_bug
          end
          if bug.product == "Research" && related_bug.product == "Research"
            bug.snort_research_to_research_bugs << related_bug unless bug.snort_research_to_research_bugs.include? related_bug
            related_bug.snort_research_to_research_bugs << bug unless related_bug.snort_research_to_research_bugs.include? bug
          end
          return {:status => "success", :product => bug.product}.to_json
        end

        desc "remove association of a bug"
        params do
          requires :bug_id, type: Integer, desc: "bugzilla id of the bug"
          requires :relate_id, type: Integer, desc: "related bugzilla id to remove"
        end
        delete 'remove_bug_relation/:bug_id/:relate_id' do
          authorize!(:destroy, EscalationLink)
          bug = Bug.where(id: params['bug_id']).first
          return {:error => 'bug not found'}.to_json unless bug
          authorize!(:update, bug)
          related_bug = Bug.where(id: params['relate_id']).first
          return {:error => 'related bug not found'}.to_json unless related_bug
          if bug.product == "Research" && related_bug.product == "Escalations"
            bug.snort_escalation_bugs.delete(related_bug)  if bug.snort_escalation_bugs.include? related_bug
          end
          if bug.product == "Escalations" && related_bug.product == "Research"
            bug.snort_research_bugs.delete(related_bug)  if bug.snort_research_bugs.include? related_bug
          end
          if bug.product == "Research" && related_bug.product == "Research"
            bug.snort_research_to_research_bugs.delete(related_bug)  if bug.snort_research_to_research_bugs.include? related_bug
            related_bug.snort_research_to_research_bugs.delete(bug)  if related_bug.snort_research_to_research_bugs.include? bug
          end
          BugBlocker.where(snort_blocked_bug: bug, snort_blocker_bug: related_bug).delete_all
          BugBlocker.where(snort_blocker_bug: bug, snort_blocked_bug: related_bug).delete_all
          return {:status => "success", :product => bug.product}.to_json
        end

        params do
          requires :bug_id, type: Integer, desc: "bugzilla id of the bug"
          optional :comment, type: String, desc: "a comment about acknowledging the escalation"
        end
        patch ':bug_id/acknowledge' do
          authorize!(:acknowledge_bug, EscalationBug)
          bug = Bug.where(id: permitted_params['bug_id']).first
          raise 'bug not found' unless bug
          xmlrpc = Bugzilla::Bug.new(bugzilla_session)
          authorize!(:acknowledge_bug, bug)
          bug.acknowledge_bug(permitted_params['comment'].nil? ? "Escalation has been acknowledged by #{bug.user&.display_name}." : permitted_params['comment'], xmlrpc)
        end

        # TODO If this is on escalations should it be in the escalation API?
        desc "subscribe and acknowledge to a bug escalation"
        params do
          requires :id, type: String, desc: "id of the bug"
          requires :committer, type: Boolean, desc: "is this a committer subscribe"
          optional :comment, type: String, desc: "a comment about acknowledgeing the escalation"
        end
        post ':id/subscribe-acknowledge' do
          authorize!(:acknowledge_bug, EscalationBug)
          bug = Bug.where(id: permitted_params[:id]).where("classification <= ?", User.class_levels[current_user.class_level]).first
          authorize!(:acknowledge_bug, bug)
          unless bug.nil?
            begin
              if params[:committer]
                if bug.committer == current_user
                  return {error: 'already subscribed to this bug'}
                else
                  options = Rails.env.development? ? {:ids => permitted_params[:id], :qa_contact => Rails.configuration.backend_auth[:authenticate_email]} : {:ids => permitted_params[:id], :qa_contact => current_user.email}
                  Bugzilla::Bug.new(bugzilla_session).update(options.to_h)
                  Bug.update(permitted_params[:id], committer_id: current_user.id, acknowledged: true)
                end
              else
                if current_user.bugs.exists?(bug.id)
                  return {error: 'already subscribed to this bug'}
                else
                  options = Rails.env.development? ? {:ids => permitted_params[:id], :assigned_to => Rails.configuration.backend_auth[:authenticate_email]} : {:ids => permitted_params[:id], :assigned_to => current_user.email}
                  Bugzilla::Bug.new(bugzilla_session).update(options.to_h)
                  current_user.bugs << bug
                  Bug.update(permitted_params[:id], state: "ASSIGNED") unless ['PENDING', 'FIXED', 'WONTFIX', 'INVALID', 'LATER'].include? bug.state
                  xmlrpc = Bugzilla::Bug.new(bugzilla_session)
                  bug.acknowledge_bug(permitted_params['comment'].nil? ? "This escalation has been taken and there by acknowledged by #{current_user&.display_name}" : permitted_params['comment'], xmlrpc)
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


        #TODO api endpoint for Bugzilla 5

      end
    end
  end
end
