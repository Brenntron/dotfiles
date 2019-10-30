class Bridge::AmpPatternUpdateEvent < Bridge::BaseMessage
  def initialize(addressee: 'talos-intelligence')
    super(channel: 'amp-patterns-update',
          addressee: addressee)
  end

  def post(amp_patterns:)
    super(message: {amp_patterns: amp_patterns})
  end

  # handle_asynchronously :post, :queue => "amp_patterns_update"
end
