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
          requires :id, type: String, desc: "id of the bug"
          optional :summary, type: String, desc: "A brief description of the bug being filed."
          # all the params we need to permit must to go here
        end
        put ":id", root: "bug" do
          bug = Bug.where(id: permitted_params[:id])
          options = {
              :ids      => permitted_params[:id],
              :summary => permitted_params[:summary]
              #all the options we want to possily include
          }
          return bug.update_bug(bugzilla_session, options)
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
              :description => permitted_params[:bug][:description]
          }
          new_bug = Bugzilla::Bug.new(bugzilla_session).create(options)#the bugzilla session is where we authenticate
          new_bug_id = new_bug["id"]

          Bug.create(
              :id => new_bug_id,
              :bugzilla_id => new_bug_id,
              :product => permitted_params[:bug][:product],
              :component => permitted_params[:bug][:component],
              :summary => permitted_params[:bug][:summary],
              :version => permitted_params[:bug][:version],
              :description => permitted_params[:bug][:description]
          )
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