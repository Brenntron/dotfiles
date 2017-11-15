module PeakeBridge
  class CatcherEvent < BaseMessage
    def initialize(bugzilla_id: nil, new_state: nil)
      super(channel: 'catcher',
            addressee: 'catcher')
      @bugzilla_id = bugzilla_id
      @new_state = new_state
    end

    def post(bugzilla_id: @bugzilla_id, new_state: @new_state)
      super(body: {bugzilla_id: bugzilla_id, new_state: new_state})
    end
  end
end
