# Just call Talos Intelligence
# If we use this for many more things, break Base out into inherited classes.
class TiApi::Base
  include ApiRequester::ApiRequester
  set_api_requester_config Rails.configuration.talos_intelligence
  set_default_request_type :json

end
