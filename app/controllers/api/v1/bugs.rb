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
        get "import_all_bugs", root: :bugs do
          xmlrpc_token = current_user.first.bugzilla_token        #We need to figure out how to populate the current user properly
          if xmlrpc_token
            xmlrpc = Bugzilla::Bug.new(bugzilla_session)
            last_updated = Time.now
            new_bugs = xmlrpc.search(creation_time:last_updated)    #then we need to go over all new bugs and import them

            new_bugs['bugs'].each do |item|
              Bug.find_or_create_by(bugzilla_id:item['id']) do |new_record|
                new_record.id        = item['id']
                new_record.state     = Bug.get_state(item['status'],item['resolution'])
                new_record.summary   = item['summary']
                new_record.user      = User.find_or_create_by(email:item['assigned_to'])
                new_record.committer = User.find_or_create_by(email: item['qa_contact'])
              end
            end
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
          requires :id, type:String, desc:"id of the bug"
        end
        put ":id", root: "bug" do
          Bug.where(id: permitted_params[:id])
        end

      end
    end
  end
end