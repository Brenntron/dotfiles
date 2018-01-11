class PeakeBridge::MessagesController < ApplicationController
  def fp_create

    sender = envelope_params[:sender]
    Rails.logger.debug("Analyst Console recieved message, on channel fp_create from sender #{sender.inspect}")

    false_positive = FalsePositive.create_from_params(false_positive_params,
                                                      attachments_attrs: attachments_params,
                                                      sender: sender)


    conn = PeakeBridge::FpCreatedEvent.new(addressee: sender,
                                           source_authority: false_positive.source_authority)
    response = conn.post(false_positive_id: false_positive.id,
                         source_key: false_positive.source_key)
    # Rails.logger.debug("PeakeBridge response.body = #{response.body.inspect}")


    render plain: "fp_create id: #{false_positive.id}", status: :ok

  rescue => except
    log_exception(except)
    render plain: except.to_s, status: :internal_server_error
  end

  # Add route for specific channels to their own action under the channels collection.
  # When there is no route, it defaults to the create action.
  def create
    channel = params[:channel_id]
    message = "Analyst Console recieved unknown (unrouted) message, on channel #{channel.inspect}"

    Rails.logger.warn(message)

    # render plain: "Analyst Console recieved unknown message, on channel #{channel.inspect}"
    # raise "Analyst Console recieved unknown message, on channel #{channel.inspect}"
    render plain: message,
           status: :internal_server_error
  end

  private

  def log_exception(except)
    Rails.logger.error(except.to_s)
    except.backtrace[0..5].each {|line| Rails.logger.error(line)}
  end

  def envelope_params
    params.require(:envelope).permit(:channel, :sender, :addressee)
  end

  def message_params
    params.require(:message)
  end

  def false_positive_params
    message_params.require(:false_positive)
        .permit(:user_email, :sid, :description, :source_key, :os, :version, :built_from, :pcap_lib, :cmd_line_options)
  end

  def attachments_params
    # params.require(:message).require(:false_positive).require(:attachments)
    message_params.require(:false_positive)['attachments']
  end
end
