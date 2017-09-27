module PeakeBridge
  class ChannelsController < ApplicationController
    def index
      @channels =
          [
              { name: 'self-test', sender: 'analyst-console', subscribers: ['analyst-console'] },
              { name: 'bug-state-change', sender: 'analyst-console', subscribers: ['talos-intelligence', 'clam-av'] },
              { name: 'false-positive', sender: 'talos-intelligence', subscribers: ['analyst-console'] }
          ]
    end
  end
end
