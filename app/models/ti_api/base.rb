# Just call Talos Intelligence
# If we use this for many more things, break Base out into inherited classes.
class TiApi::Base
  include ApiRequester::ApiRequester
  set_api_requester_config Rails.configuration.talos_intelligence
  set_default_request_type :json

  def self.update_amp_patterns(amp_naming_convention, old_position:)
    byebug
    input = {
        ticode: Rails.configuration.talos_intelligence.api_key,
        old_position: old_position,
        # position: amp_naming_convention.table_sequence,
        # pattern: amp_naming_convention.pattern,
        # example: amp_naming_convention.example,
        # description: amp_naming_convention.engine_description,
        # notes: amp_naming_convention.public_notes
    }
    call_request(:put, 'api/v1/amp_naming_patterns', input: input)
  end
end
