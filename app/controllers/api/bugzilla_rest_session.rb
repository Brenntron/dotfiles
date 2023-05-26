# Module to get bugzilla REST API login token from HTTP request headers
# This is broken out into its own module, because not all API controllers will need this.
# For instance, the /api/v2/bugs will always need this, but /api/v2/rule_updates does not.
# Standard return for missing a token can also be handled here (not yet implemented).
module API::BugzillaRestSession
  extend ActiveSupport::Concern

  included do
    helpers do
      def bugzilla_rest_session
        #token = env['rack.session']['bugzilla_rest_api_token']
        #BugzillaRest::Session.new(api_key: current_user.bugzilla_api_key, token: token)
        ### this is a drop and go replacement of bugzilla rest session functionality since bugzilla is going away
        # all we need is a local "proxy" to "act" like bugzilla so that functionality can continue on as if nothing happened
        # EscalationTicket acts as that proxy, pretending to be bugzilla,
        # for the sake of continuity it will "behave" like bugzilla
        EscalationTicket
      end
    end
  end
end
