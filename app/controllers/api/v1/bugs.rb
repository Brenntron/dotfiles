module API
  module V1
    class Bugs < Grape::API
      include API::V1::Defaults

      resource :bugs do

        desc "get latest bugs from bugzilla"
        get 'import_all' do
          xmlrpc_token = current_user.bugzilla_token #We need to figure out how to populate the current user properly
          if xmlrpc_token
            xmlrpc = Bugzilla::Bug.new(bugzilla_session)
            last_updated = Bug.get_last_import_all()
            new_bugs = xmlrpc.search(last_change_time: last_updated) #then we need to go over all new bugs and import them
            Bug.import(xmlrpc,new_bugs)
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
            xmlrpc_token = current_user.bugzilla_token #We need to figure out how to populate the current user properly
            if xmlrpc_token
              xmlrpc = Bugzilla::Bug.new(bugzilla_session)
              new_bug = xmlrpc.get(permitted_params[:id])
              Bug.import(xmlrpc,new_bug).to_s
            else
              false
            end
          end
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
          requires :bug, type: Hash do
            optional :user_id, type: Integer, desc: "the user this bug is assigned to"
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
          end

        end
        put ":id", root: "bug" do
          options = {
              :ids => params[:id],
              :user_id => permitted_params[:bug][:user_id],
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
              #all the options we want to possibly include
          }
          options.reject! { |k, v| v.nil? }
          update_params = permitted_params[:bug].reject { |k, v| v.nil? }
          Bug.update(params[:id], update_params)
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
          xmlrpc_token = current_user.first.bugzilla_token #We need to figure out how to populate the current user properly
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
          xmlrpc_token = current_user.first.bugzilla_token #We need to figure out how to populate the current user properly
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
          xmlrpc_token = current_user.first.bugzilla_token #We need to figure out how to populate the current user properly
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