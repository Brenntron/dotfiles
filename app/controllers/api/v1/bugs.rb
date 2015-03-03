module API
  module V1
    class Bugs < Grape::API
      include API::V1::Defaults

      resource :bugs do
        params do
          use :pagination
        end
        desc "Return all bugs"
        get "", root: :bugs do
          if params[:page]
            bugs = Bug.page(params[:page]).per(params[:per_page])
            render bugs, { meta: {total_pages: bugs.total_pages} }
          else
            Bug.all
          end
        end

        desc "get a bug"
        params do
          requires :id, type: String, desc: "ID of the bug"
        end
        get :id, root: "bug" do
          Bug.where(id: permitted_params[:id])
        end

        desc "update a bug"
        params do
          requires :bug, type: Hash do
            requires :product, type: String, desc: "The name of the product the bug is being filed against."
            requires :component, type: String, desc: "The name of a component in the product above."
            requires :summary, type: String, desc: "A brief description of the bug being filed."
            requires :version, type: String, desc: "A version of the product above; the version the bug was found in."
            requires :description, type: String, desc: "A full text description of the bug"
            optional :state, type: String, desc: "The state of the bug, Open, Closed, ReOpened,etc"
            optional :creator, type: String, desc: "The person who created the bug"
            optional :opsys, type:String, desc: "The operating system that this bug affects"
            optional :platform, type:String , desc: "What platform this bug runs on"
            optional :priority, type:String , desc: "How soon should this bug get fixed"
            optional :severity, type:String, desc: "How terrible is this bug"
            optional :classification, type:Integer, desc: "Who should see this bug. Higher classification restricts more people from seeing it."
          end
        end
        put ":id", root: "bug" do
          options = {
              :ids      => params[:id],
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
          options.reject! {|k,v| v.nil?}
          update_params = permitted_params[:bug].reject {|k, v| v.nil?}

          updated_bug = Bugzilla::Bug.new(bugzilla_session).update(options)
          if updated_bug
            Bug.update(params[:id], update_params)
          else
            puts "changes not saved to bugzilla (#{update_params})"
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
          }

          new_bug = Bugzilla::Bug.new(bugzilla_session).create(options)#the bugzilla session is where we authenticate

          new_bug_id = new_bug["id"]
          options.delete("Bugzilla_token")
          options[:id] = new_bug_id
          options[:bugzilla_id] = new_bug_id

          Bug.create(options)

        end

        desc "get latest bugs from bugzilla"
        get :import_all, root: "bug" do
          xmlrpc_token = current_user.first.bugzilla_token #We need to figure out how to populate the current user properly
          if xmlrpc_token
            xmlrpc = Bugzilla::Bug.new(bugzilla_session)
            last_updated = Bug.get_latest()
            new_bugs = xmlrpc.search(last_change_time: last_updated) #then we need to go over all new bugs and import them
            Bug.import(new_bugs)
            "true"
          else
            "false"
          end
        end

        desc "import one bug from bugzilla"
        params do
          requires :id, type: Integer, desc: "Bugzilla id."
        end
        get "import/:id", root: "bug" do
          xmlrpc_token = current_user.first.bugzilla_token #We need to figure out how to populate the current user properly
          if xmlrpc_token
            new_bug = Bugzilla::Bug.new(bugzilla_session).get(permitted_params[:id])['bugs']
            Bug.import(new_bug).to_s
          else
            false
          end
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
            return bug.bug_state(bugzilla_session, permitted_params[:notes],status, resolution)
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
            return bug.bug_state(bugzilla_session, permitted_params[:notes],status, resolution)
          else
            false
          end
        end

      end
    end
  end
end