module PeakeBridge
  class ConsoleEvent < BaseMessage
    def initialize(bugzilla_id: nil, new_state: nil)
      super(channel: 'analyst-console',
            addressee: 'analyst-console')
      @bugzilla_id = bugzilla_id
      @new_state = new_state
    end

    def post(bugzilla_id: @bugzilla_id, new_state: @new_state)
      super(body: {bugzilla_id: bugzilla_id, new_state: new_state})
    end
  end
end
