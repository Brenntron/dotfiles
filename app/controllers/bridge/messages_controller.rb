class Bridge::MessagesController < ApplicationController
  def fp_create(params)
    sender = envelope_params[:sender]
    Rails.logger.debug("Analyst Console recieved message to create a false positive bug from sender #{sender}")
    false_positive = FalsePositive.where(source_key:false_positive_params['source_key']).first
    unless false_positive
      false_positive = FalsePositive.create_from_params(false_positive_params,
                                                        attachments_attrs: attachments_params,
                                                        sender: sender)
    end
    Thread.new { false_positive.create_bug_action(bugzilla_session) }
    return_message = {
        "envelope":
            {
                "channel": "poll-from-bridge",
                "addressee": "snort-org",
                "sender": "analyst-console"
            },
        "message": {"source_key":params["source_key"],"ac_status":"RECEIVED"},
    }
    render json: return_message, status: :ok

  rescue => except
    log_exception(except)
    render plain: except.message, status: :internal_server_error
  end

  def get_messages
    #if peake bridge ever asks for info from AC this is where you would return a response
    return_message = {

    }
    render json: return_message, status: :ok
  rescue => except
    log_exception(except)
    render plain: except.message, status: :internal_server_error
  end
  def messages_from_bridge

    case envelope_params["sender"]
      when "snort-org"
        fp_create(false_positive_params)
      when "talos-ingelligence"
    end

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
    params.require(:message).permit(:user_email, :source_key, fp_attrs: {})
  end

  def attachments_params
    params.require(:message).permit(attachments: [:file_name,:url,:location,:file_type_name])
  end
end
