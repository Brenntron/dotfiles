module PeakeBridge
  class BugStateChangeEvent < BaseMessage
    def initialize(bugzilla_id: nil, new_state: nil)
      super(channel: 'bug-state-change',
            addressee: 'analyst-console')
      @bugzilla_id = bugzilla_id
      @new_state = new_state
    end

    def post(bugzilla_id: @bugzilla_id, new_state: @new_state)
      super(message: {bugzilla_id: bugzilla_id, new_state: new_state})
    end
  end
end
