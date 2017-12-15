module API
  module BugzillaLogin
    extend ActiveSupport::Concern

    included do
      helpers do
        def bugzilla_session
          xmlrpc = Bugzilla::XMLRPC.new(Rails.configuration.bugzilla_host)
          if current_user
            xmlrpc.token = request.headers['Xmlrpc-Token']
          end
          xmlrpc
        end
      end
    end
  end
end
