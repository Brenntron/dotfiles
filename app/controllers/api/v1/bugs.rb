module API
  module V1
    class Bugs < Grape::API
      include API::V1::Defaults

      resource :bugs do
        desc "test the websocket"
        get 'websocket' do
          bug = Bug.first
          record = { resource: 'bug',
                     action: 'update',
                     id: bug.id,
                     obj: bug }
          PublishWebsocket.push_changes(record)
        end

        desc "get job queue for a bug"
        params do
          requires :id, type: Integer, desc: "Bugzilla id."
        end
        get '/queue/:id' do
          begin
            @bug = Bug.find_by_id(params[:id])
            response = {}
            response[:status] = 'success'
            response[:data] = []
            bug_queue = []

            tasks = @bug.tasks.any_relations.reverse_chron

            tasks.each do |task|
              task.check_timeout
              task.reload
              response_task = {}
              response_task['id'] = task.id
              response_task['rule_list'] = task.task_type == Task::TASK_TYPE_LOCAL_TEST ? task.rules.map {|rule| rule.new_rule? ? 'new-rule' : "#{rule.gid}:#{rule.sid}:#{rule.rev}" }.join('; ') : ""
              response_task['completed'] = task.completed
              response_task['failed'] = task.failed
              response_task['cvs_username'] = User.find(task.user_id).cvs_username
              response_task['task_type'] = task.task_type
              response_task['result'] = task.result
              response_task['created_at'] = task.created_at.strftime("%m/%d/%y %H:%M:%S")
              bug_queue << response_task
            end
            response[:data] = bug_queue
            response.to_json
          rescue
            Rails.logger.error($!)
            Rails.logger.error($!.backtrace.join("\n"))
            response = {}
            response[:status] = "fail"
            response[:error] = "Something went wrong. The job queue has not been updated."
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
          xmlrpc_token = request.headers['Xmlrpc-Token']
          if xmlrpc_token
            xmlrpc = Bugzilla::Bug.new(bugzilla_session)
            last_updated = Bug.get_last_import_all()
            new_bugs = xmlrpc.search(last_change_time: last_updated) #then we need to go over all new bugs and import them
            Bug.bugzilla_import(current_user, xmlrpc,xmlrpc_token,new_bugs)
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
                Bug.synch_attachments(xmlrpc,new_bug, current_user).to_s
              else
                # history
                Bug.synch_history(xmlrpc,new_bug).to_s
              end
            end
          else
            false
          end
        end

        desc "import one bug from bugzilla"
        params do
          requires :id, type: Integer, desc: "Bugzilla id."
        end
        route_param "import/:id" do
          get do
            xmlrpc_token = request.headers['Xmlrpc-Token']

            if xmlrpc_token
              Rails.logger.debug("bugzilla: Importing bug: #{params[:id]}")
              progress_bar = Event.create(user:current_user.display_name,action:"import_bug:#{params[:id]}",description:"#{request.headers["Token"]}",progress:10)

              begin
                xmlrpc = Bugzilla::Bug.new(bugzilla_session)
                new_bug = xmlrpc.get(permitted_params[:id])
                initial_bug_state = Bug.where(id: permitted_params[:id]).first
                if initial_bug_state
                  initial_bug_state = initial_bug_state.clone
                end
                progress_bar.update_attribute("progress", 10)
                #create the bug from bugzilla
                bug = Bug.bugzilla_import(current_user, xmlrpc,xmlrpc_token,new_bug)
                #parse the bug summary
                parsed = bug.parse_summary
                bug_rules = bug.rules.map {|r| r.id}
                progress_bar.update_attribute("progress", 50)
                bug.load_rules_from_sids(parsed[:sids])
                progress_bar.update_attribute("progress", 60)
                parsed[:tags].each do |tag|
                  bug.import_report[:new_tags] += 1 unless bug.tags.include?(tag)
                  bug.tags << tag unless bug.tags.include?(tag)
                end
                progress_bar.update_attribute("progress", 75)
                parsed[:refs].each do |ref|
                  bug.import_report[:new_refs] += 1 unless bug.references.map {|r| r.reference_data}.include? ref.reference_data
                  bug.references << ref unless bug.references.map {|r| r.reference_data}.include? ref.reference_data
                  Exploit.find_exploits(ref)
                end
                progress_bar.update_attribute("progress", 90)
                #save the bug
                bug.save

                bug.clear_rule_tested
                if initial_bug_state
                  report = bug.compile_import_report(initial_bug_state)
                end
                progress_bar.update_attribute("progress", 100)
                sleep(2)
                {:status => "success", :import_report => report}.to_json
              rescue Exception => e
                Rails.logger.info e
                progress_bar.update_attribute("progress", -1)
                {:error => e.to_s}.to_json
              end
            else
              false
            end
          end
        end

        desc "delete a rule with this bug"
        params do
          requires :link, type: String, desc: "bug:bug_id&rule:rule_id"
        end
        delete '/rules/:link' do
          Bug.where(id:permitted_params[:link].split(':')[0]).first.rules.destroy(permitted_params[:link].split(':')[1]).first
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
              :bugzilla_id  => /-/.match(permitted_params[:id_range]) ? nil : permitted_params[:id_range],
              :state        => permitted_params[:state] ? permitted_params[:state] : nil,
              :user_id      => permitted_params[:user_id] ? permitted_params[:user_id] : nil,
              :committer_id => permitted_params[:committer] ? permitted_params[:committer] : nil
          }.reject{|k,v| v.blank?}
          range = {
              :gte      => /-/.match(permitted_params[:id_range]) ? /(\d+)-/.match(permitted_params[:id_range])[1] : nil,
              :lte   => /-/.match(permitted_params[:id_range]) ? /-(\d+)/.match(permitted_params[:id_range])[1] : nil,
          }.reject{|k,v| v.blank?}

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
          end

        end
        put ":id", root: "bug" do
          bug     = Bug.find(permitted_params[:id])
          tags = params[:bug][:tag_names]

          editor = User.find(permitted_params[:bug][:user_id])
          reviewer = User.find(permitted_params[:bug][:committer_id])
          updated_bug_state = Bug.get_new_bug_state(bug, permitted_params[:bug][:state], editor.email)

          options = {
              :ids => permitted_params[:id],
              :assigned_to => editor.email,
              :status => updated_bug_state[:status],
              :resolution => updated_bug_state[:resolution],
              :comment => updated_bug_state[:comment],
              :qa_contact => reviewer.email
          }
          update_params = {
              :user => editor,
              :state => updated_bug_state[:state],
              :status => updated_bug_state[:status],
              summary: updated_bug_state[:summary],
              :resolution => updated_bug_state[:resolution],
              :assigned_at => updated_bug_state[:assigned_at],
              :pending_at => updated_bug_state[:pending_at],
              :resolved_at => updated_bug_state[:resolved_at],
              :reopened_at => updated_bug_state[:reopened_at],
              :work_time => updated_bug_state[:work_time],
              :rework_time => updated_bug_state[:rework_time],
              :review_time => updated_bug_state[:review_time],
              :committer => reviewer
          }

          if permitted_params[:bug][:new_research_notes]
            update_params = {
                :research_notes => permitted_params[:bug][:new_research_notes]
            }
          elsif permitted_params[:bug][:new_committer_notes]
            update_params = {
                :committer_notes => permitted_params[:bug][:new_committer_notes]
            }
          end
          #if a comment is made about a state then add it to the history here.
          if permitted_params[:bug][:state_comment]
            note_options = {
                :id => permitted_params[:id],
                :comment => permitted_params[:bug][:state_comment],
                :note_type => "research",
                :author => current_user.email,
            }
            Note.process_note(note_options, bugzilla_session)
          end
          # update the tags
          bug.tags.delete_all if bug.tags.exists?
          if tags
            tags.each do |tag|
              new_tag = Tag.find_or_create_by(name: tag)
              bug.tags << new_tag
            end
          end


          # update the summary
          bug.update_summary(permitted_params[:bug][:summary])

          update_params[:product] = permitted_params[:bug][:product]
          update_params[:component] = permitted_params[:bug][:component]
          update_params[:summary] = permitted_params[:bug][:summary]
          update_params[:version] = permitted_params[:bug][:version]
          update_params[:state] = permitted_params[:bug][:state]
          update_params[:opsys] = permitted_params[:bug][:opsys]
          update_params[:platform] = permitted_params[:bug][:platform]
          update_params[:priority] = permitted_params[:bug][:priority]
          update_params[:severity] = permitted_params[:bug][:severity]
          update_params[:classification] = permitted_params[:bug][:classification]

          # update the database
          # (do this first so we can compose the summary properly to send to bugzilla)
          update_params.reject! { |k, v| v.nil? }
          Bug.update(permitted_params[:id], update_params)


          options[:ids] = permitted_params[:id]
          options[:product] = permitted_params[:bug][:product]
          options[:component] = permitted_params[:bug][:component]
          options[:summary] = bug.summary
          options[:version] = permitted_params[:bug][:version]
          options[:state] = permitted_params[:bug][:state]
          options[:creator] = permitted_params[:bug][:creator]
          options[:opsys] = permitted_params[:bug][:opsys]
          options[:platform] = permitted_params[:bug][:platform]
          options[:priority] = permitted_params[:bug][:priority]
          options[:severity] = permitted_params[:bug][:severity]
          options[:classification] = permitted_params[:bug][:classification]

          # update buzilla (if needed)
          options.reject! { |k, v| v.nil? } if options
          Bugzilla::Bug.new(bugzilla_session).update(options.to_h) unless options.blank?

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
          bug = Bug.create(
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
          Bug.synch_history(xmlrpc,new_bug_history).to_s

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
            error!({error: "Access denied.",message: e.message}, 200)
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
        end
        post ':id/subscribe' do
          bug = Bug.where(id: permitted_params[:id]).where("classification <= ?", User.class_levels[current_user.class_level]).first
          unless bug.nil?
            begin
              if current_user.bugs.exists?(bug.id)
                return {error: 'already subscribed to this bug'}
              else
                options = {:ids => permitted_params[:id], :assigned_to => current_user.email}
                Bugzilla::Bug.new(bugzilla_session).update(options.to_h)
                current_user.bugs << bug
                Bug.update(permitted_params[:id], state:"ASSIGNED")
              end
              return true
            rescue XMLRPC::FaultException => e
              return {error: "#{e}"}
            end
          end
          return {error: 'cannot find bug to subscribe'}
        end


        desc "unsubscribe to a bug"
        params do
          requires :id, type: String, desc: "id of the bug"
        end
        post ':id/unsubscribe' do
          bug = current_user.bugs.where(id: permitted_params[:id])
          unless bug.nil?
            begin
              vrt_incoming = User.where(email: "vrt-incoming@sourcefire.com").first
              options = {:ids => permitted_params[:id], :reset_assigned_to => true,:assigned_to => "vrt-incoming@sourcefire.com"}
              Bugzilla::Bug.new(bugzilla_session).update(options.to_h)
              current_user.bugs.delete(bug)
              Bug.update(permitted_params[:id], state:"NEW")
              vrt_incoming.bugs << bug
              return true
            rescue XMLRPC::FaultException => e
              return {error: "#{e}"}
            end

            return true
          end
          return false
        end

      end
    end
  end
end
