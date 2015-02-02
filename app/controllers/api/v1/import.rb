module API
  module V1
    class Import < Grape::API
      include API::V1::Defaults

      resource :import do
        desc "get bugs from bugzilla"
        get "all_bugs", root: :import do
          xmlrpc_token = current_user.first.bugzilla_token        #We need to figure out how to populate the current user properly
          if xmlrpc_token
            xmlrpc = Bugzilla::Bug.new(bugzilla_session)
            this_is_a_bug = xmlrpc.get('116261')['bugs'].first    #then we need to go over all new bugs and import them
          end
        end
      end
    end
  end
end