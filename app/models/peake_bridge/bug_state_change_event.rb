module PeakeBridge
  class BugStateChangeEvent < BasicPeakeBridge
    def initialize(bugzilla_id: nil, new_state: nil)
      super(channel: 'bug-state-change',
            addressee: 'analyst-console',
            host: "localhost",
            port: 2966,
            ssl: false,
            uri_base: '/peakebridge/channels')
      @bugzilla_id = bugzilla_id
      @new_state = new_state
    end

    def post(bugzilla_id: @bugzilla_id, new_state: @new_state)
      super(body: {bugzilla_id: bugzilla_id, new_state: new_state})
    end
  end
end
