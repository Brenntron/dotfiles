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

        desc "get latest bugs from bugzilla"
        get 'import_all' do
          xmlrpc_token = request.headers['Xmlrpc-Token']
          if xmlrpc_token
            xmlrpc = Bugzilla::Bug.new(bugzilla_session)
            last_updated = Bug.get_last_import_all()
            new_bugs = xmlrpc.search(last_change_time: last_updated) #then we need to go over all new bugs and import them
            Bug.bugzilla_import(xmlrpc,new_bugs)
            "true"
          else
            "false"
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
              begin
                xmlrpc = Bugzilla::Bug.new(bugzilla_session)
                new_bug = xmlrpc.get(permitted_params[:id])
                #create the bug from bugzilla
                Bug.bugzilla_import(xmlrpc,new_bug).to_s
                bug = Bug.where(id:params[:id]).first
                #parse the bug summary
                parsed = bug.parse_summary
                bug_rules = bug.rules.map {|r| r.id}
                parsed[:sids].each do |sid|
                  rule = Rule.import_rule(sid)
                  bug.rules << rule unless bug_rules.include? rule.id
                end
                parsed[:tags].each do |tag|
                  bug.tags << Tag.find_or_create(tag)
                end
                parsed[:refs].each do |ref|
                  Exploit.find_exploits(ref)
                  bug.references << ref
                end
                #use the references to find any existing exploits


                #save the bug
                bug.save
              rescue Exception => e
                false
              end
            else
              false
            end
          end
        end

        desc "link a rule with this bug"
        params do
          requires :link, type: String, desc: "bug:bug_id&rule:rule_id"
        end
        post '/rules/:link' do
          rule_id = permitted_params[:link].split(':')[1]
          rule = Rule.where(id:rule_id).empty? ? Rule.import_rule(rule_id) : Rule.where(id:rule_id).first
          Bug.where(id:permitted_params[:link].split(':')[0]).first.rules << rule
        end

        desc "unlink a rule with this bug"
        params do
          requires :link, type: String, desc: "bug:bug_id&rule:rule_id"
        end
        delete '/rules/:link' do
          Bug.where(id:permitted_params[:link].split(':')[0]).first.rules.destroy(permitted_params[:link].split(':')[1]).first
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
          Bug.check_permission(current_user, Bug.search(permitted_params[:summary], terms, range)).map { |r| hits.push(r.id)}
          hits
        end

        desc "get a single bug"
        params do
          requires :id, type: String, desc: "ID of the bug"
        end
        get ':id' do
          Bug.where(id: permitted_params[:id]).page(params[:page]).per(params[:per_page]).where("classification <= ?", User.class_levels[current_user.class_level])
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
            requires :product, type: String, desc: "The name of the product the bug is being filed against."
            requires :component, type: String, desc: "The name of a component in the product above."
            requires :summary, type: String, desc: "A brief description of the bug being filed."
            requires :version, type: String, desc: "A version of the product above; the version the bug was found in."
            optional :description, type: String, desc: "A full text description of the bug"
            optional :state, type: String, desc: "The state of the bug, Open, Closed, ReOpened,etc"
            optional :state_id, type: String, desc: "The new state of the bug, Open, Closed, ReOpened,etc"
            optional :creator, type: String, desc: "The person who created the bug"
            optional :opsys, type: String, desc: "The operating system that this bug affects"
            optional :platform, type: String, desc: "What platform this bug runs on"
            optional :priority, type: String, desc: "How soon should this bug get fixed"
            optional :severity, type: String, desc: "How terrible is this bug"
            optional :classification, type: Integer, desc: "Who should see this bug. Higher classification restricts more people from seeing it."
            optional :new_research_notes, type: String, desc: "Current working draft of research notes"
            optional :new_committer_notes, type: String, desc: "Current working draft of committer notes"
            optional :editor_id, type: String, desc: "id of the new user to be assigned to the bug"
            optional :reviewer_id, type: String, desc: "id of the new committer to be assigned to the bug"
          end

        end
        put ":id", root: "bug" do
          bug     = Bug.find(permitted_params[:id])
          options = {}
          update_params = {}
          if permitted_params[:bug][:editor_id]
            state = nil
            editor = User.find(permitted_params[:bug][:editor_id])
            state_params = Bug.update_state(bug, state, editor.email)
            options = {
                :ids => permitted_params[:id],
                :assigned_to => editor.email,
                :status => state_params[:status],
                :resolution => state_params[:resolution],
                :comment => state_params[:comment]
            }
            update_params = {
                :user => editor,
                :state => state_params[:state],
                :status => state_params[:status],
                :resolution => state_params[:resolution],
                :assigned_at => state_params[:assigned_at],
                :pending_at => state_params[:pending_at],
                :resolved_at => state_params[:resolved_at],
                :reopened_at => state_params[:reopened_at],
                :work_time => state_params[:work_time],
                :rework_time => state_params[:rework_time],
                :review_time => state_params[:review_time]
            }
          elsif permitted_params[:bug][:reviewer_id]
            reviewer = User.find(permitted_params[:bug][:reviewer_id])
            options = {
                :ids => permitted_params[:id],
                :qa_contact => reviewer.email
            }
            update_params = {
                :committer => reviewer
            }
          elsif permitted_params[:bug][:state_id]
            state_params = Bug.update_state(bug, permitted_params[:bug][:state_id], nil)
            options = {
                :ids => permitted_params[:id],
                :status => state_params[:status],
                :resolution => state_params[:resolution],
                :comment => state_params[:comment]
            }
            update_params = {
                :state => state_params[:state],
                :status => state_params[:status],
                :resolution => state_params[:resolution],
                :assigned_at => state_params[:assigned_at],
                :pending_at => state_params[:pending_at],
                :resolved_at => state_params[:resolved_at],
                :reopened_at => state_params[:reopened_at],
                :work_time => state_params[:work_time],
                :rework_time => state_params[:rework_time],
                :review_time => state_params[:review_time]
            }
          elsif permitted_params[:bug][:new_research_notes]
            update_params = {
                :research_notes => permitted_params[:bug][:new_research_notes]
            }
          elsif permitted_params[:bug][:new_committer_notes]
            update_params = {
                :committer_notes => permitted_params[:bug][:new_committer_notes]
            }
          end
          options[:ids] = permitted_params[:id]
          options[:product] = permitted_params[:bug][:product]
          options[:component] = permitted_params[:bug][:component]
          options[:summary] = permitted_params[:bug][:summary]
          options[:version] = permitted_params[:bug][:version]
          options[:creator] = permitted_params[:bug][:creator]
          options[:opsys] = permitted_params[:bug][:opsys]
          options[:platform] = permitted_params[:bug][:platform]
          options[:priority] = permitted_params[:bug][:priority]
          options[:severity] = permitted_params[:bug][:severity]
          options[:classification] = permitted_params[:bug][:classification]

          update_params[:product] = permitted_params[:bug][:product]
          update_params[:component] = permitted_params[:bug][:component]
          update_params[:summary] = permitted_params[:bug][:summary]
          update_params[:version] = permitted_params[:bug][:version]
          update_params[:opsys] = permitted_params[:bug][:opsys]
          update_params[:platform] = permitted_params[:bug][:platform]
          update_params[:priority] = permitted_params[:bug][:priority]
          update_params[:severity] = permitted_params[:bug][:severity]
          update_params[:classification] = permitted_params[:bug][:classification]

          # update buzilla (if needed)
          options.reject! { |k, v| v.nil? } if options
          Bugzilla::Bug.new(bugzilla_session).update(options) unless options.blank?
          # update the database
          update_params.reject! { |k, v| v.nil? }
          Bug.update(permitted_params[:id], update_params)

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
            optional :classification, type: Integer, desc: "Who should see this bug. Higher classification restricts more people from seeing it."
            # all the params we need to permit must to go here
          end
        end
        post "", root: "bug" do
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
              :classification => permitted_params[:bug][:classification]
          }.reject() { |k, v| v.nil? || v.empty? } #remove any nil or empty values in the hash(bugzilla doesnt like them)
          new_bug = Bugzilla::Bug.new(bugzilla_session).create(options) #the bugzilla session is where we authenticate
          new_bug_id = new_bug["id"]
          Bug.create(
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
              :classification => permitted_params[:bug][:classification] || 0 #api won't get bugs with classification of nil
          )
        end

        desc "remove a bug from the db only"
        params do
          requires :id, type: Integer, desc: "Bugzilla id."
        end
        delete ":id", root: "bug" do
          Bug.destroy(permitted_params[:id])
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
              if current_user.bugs.exists?(bug)
                return {error: 'already subscribed to this bug'}
              else
                options = {:ids => permitted_params[:id], :assigned_to => current_user.email}
                Bugzilla::Bug.new(bugzilla_session).update(options)
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
              options = {:ids => permitted_params[:id], :reset_assigned_to => true}
              Bugzilla::Bug.new(bugzilla_session).update(options)
              current_user.bugs.delete(bug)
              Bug.update(permitted_params[:id], state:"NEW")
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