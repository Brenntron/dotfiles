class Bridge::FilerepAutoResolveEvent < Bridge::BaseMessage
  # def initialize(sender_data)
  #   super(channel: 'autoresolve-filerep-ticket',
  #         addressee: 'talos-intelligence')
  #   @sender_data = sender_data
  # end
  #
  # def post
  #   super(message: {
  #       sender_data: @sender_data,
  #   })
  # end
  #
  # handle_asynchronously :post, :queue => "filerep_autoresolve"
end