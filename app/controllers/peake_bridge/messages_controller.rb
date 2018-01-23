class PeakeBridge::MessagesController < ApplicationController
  def fp_create

    sender = envelope_params[:sender]
    Rails.logger.debug("Analyst Console recieved message, on channel fp_create from sender #{sender.inspect}")

    false_positive = FalsePositive.create_from_params(false_positive_params,
                                                      attachments_attrs: attachments_params,
                                                      sender: sender)


    Thread.new { false_positive.create_bug_action(bugzilla_session, sender) }

    render plain: "fp_create id: #{false_positive.id}", status: :ok

  rescue => except
    log_exception(except)
    render plain: except.message, status: :internal_server_error
  end

  # Add route for specific channels to their own action under the channels collection.
  # When there is no route, it defaults to the create action.
  def create
    channel = params[:channel_id]
    message = "Analyst Console recieved unknown (unrouted) message, on channel #{channel.inspect}"

    Rails.logger.warn(message)

    render plain: message,
           status: :internal_server_error
  end

  private

  # @return [Bugzilla::XMLRPC] Authenticated bugzilla session
  def bugzilla_session
    begin
      unless @bugzilla_session
        bugzilla_proxy = Bugzilla::XMLRPC.new(Rails.configuration.bugzilla_host)
        bugzilla_proxy.bugzilla_login(Bugzilla::User.new(bugzilla_proxy),
                                      Rails.configuration.bugzilla_username,
                                      Rails.configuration.bugzilla_password)
        @bugzilla_session = bugzilla_proxy
      end
    rescue => except
      Rails.logger.error(except.message)
    end
    @bugzilla_session
  end

  def log_exception(except)
    Rails.logger.error(except.message)
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
