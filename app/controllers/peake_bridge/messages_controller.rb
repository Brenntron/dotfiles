class PeakeBridge::MessagesController < ApplicationController
  def fp_create

    sender = envelope_params[:sender]

    false_positive = FalsePositive.create_from_params(false_positive_params,
                                                      attachments_attrs: attachments_params,
                                                      sender: sender)
    byebug

    Rails.logger.debug("Analyst Console recieved message, on channel fp_create from sender #{sender.inspect}")

    conn = PeakeBridge::FpCreatedEvent.new(addressee: sender,
                                           source_authority: false_positive.source_authority,
                                           source_key: false_positive.source_key)

    response = conn.post(false_positive_id: false_positive.id)
    Rails.logger.debug("PeakeBridge response.body = #{response.body.inspect}")

    # render plain: "Analyst Console recieved message, on channel #{channel.inspect} to addressee #{addressee.inspect}"
    raise "Analyst Console recieved message, on channel #{channel.inspect} from #{sender.inspect} to addressee #{addressee.inspect}"
  end

  # Add route for specific channels to their own action under the channels collection.
  # When there is no route, it defaults to the create action.
  def create
    channel = params[:channel_id]

    # render plain: "Analyst Console recieved unknown message, on channel #{channel.inspect}"
    raise "Analyst Console recieved unknown message, on channel #{channel.inspect}"
  end

  private

  def envelope_params
    params.require(:envelope).permit(:channel, :sender, :addressee)
  end

  def false_positive_params
    params.require(:message).require(:false_positive)
        .permit(:user_email, :sid, :description, :id, :os, :version, :built_from, :pcap_lib, :cmd_line_options)
  end

  def attachments_params
    params.require(:message).require(:false_positive).require(:attachments)
  end
end
