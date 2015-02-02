module API
  module V1
    class Bugs < Grape::API
      include API::V1::Defaults

      resource :bugs do
        desc "Return all bugs"
        get "", root: :bugs do
          Bug.all
        end

        desc "get bugs from bugzilla"
        get "import_all", root: :bugs do
          xmlrpc_token = current_user.first.bugzilla_token #We need to figure out how to populate the current user properly
          if xmlrpc_token
            xmlrpc = Bugzilla::Bug.new(bugzilla_session)
            last_updated = Bug.get_latest()
            new_bugs = xmlrpc.search(creation_time: last_updated) #then we need to go over all new bugs and import them
            Bug.import(new_bugs)
            return true
          end
          return false
        end

        desc "import one bug from bugzilla"
        params do
          requires :id, type: Integer, desc: "Bugzilla id."
        end
        get "import/:id", root: "bug" do
          xmlrpc_token = current_user.first.bugzilla_token #We need to figure out how to populate the current user properly
          if xmlrpc_token
            new_bug = Bugzilla::Bug.new(bugzilla_session).get(permitted_params[:id])['bugs']
            Bug.import(new_bug)
            return true
          end
          return false
        end

        desc "Return a bug"
        params do
          requires :id, type: String, desc: "ID of the bug"
        end
        get ":id", root: "bug" do
          Bug.where(id: permitted_params[:id])
        end

        desc "Edit a bug"
        params do
          requires :id, type: String, desc: "id of the bug"
        end
        put ":id", root: "bug" do
          Bug.where(id: permitted_params[:id])
        end


      end
    end
  end
end