# Module to get xmlrpc bugzilla login token from HTTP request headers
# This is broken out into its own module, because not all API controllers will need this.
# For instance, the /api/v2/bugs will always need this, but /api/v2/rule_updates does not.
# Standard return for missing a token can also be handled here (not yet implemented).
module API::BugzillaLogin
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
