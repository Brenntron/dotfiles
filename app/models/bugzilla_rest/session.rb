class BugzillaRest::Session < BugzillaRest::Base

  # @return [Integer] the id of the created bug
  def create_bug(bug_attrs, assigned_user: User.vrtincoming)
    assigned_to = assigned_user&.email
    bugzilla_bug_options =
        bug_attrs.to_h.slice(*%w{product component summary version description opsys platform priority severity
                                 state creator classification})
            .reject { |key, value| value.nil? }
            .merge('assigned_to' => assigned_to)

    response_body = post('/rest/bug', bugzilla_bug_options.to_json)
    response_hash = JSON.parse(response_body)

    response_hash['id']
  end
end
