class Escalations::PeakeBridge::MessagesController < ApplicationController
  skip_before_action :require_login

  def get_messages
    Rails.logger.info("GET get_messages")
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
      when "talos-intelligence"
        Rails.logger.info("POST talos-intelligence message, on channel #{envelope_params[:channel].inspect}")
        obj_type_key, message_payload = message_params.to_h.first
        obj_type = obj_type_key.to_s.camelize

        if message_payload.respond_to?(:permit!)
          message_payload = message_payload.permit!.to_h
        end
        message_payload[:bugzilla_session] = bugzilla_session
        message_payload[:current_user] = current_user
        #return_message = obj_type.constantize.process_bridge_payload(message_payload)

        Thread.new { obj_type.constantize.process_bridge_payload(message_payload) }
        #obj_type.constantize.process_bridge_payload(message_payload)

        #return_message = {
        #    "envelope":
        #        {
        #            "channel": "ticket-acknowledge",
        #            "addressee": "talos-intelligence",
        #            "sender": "analyst-console"
        #        },
        #    "message": {"source_key":message_payload["source_key"],"ac_status":"CREATE_PENDING", "ticket_entries": "", "case_email": case_email}
        #}

        render json: {}, status: :ok
      else
        return_message = {

        }
        render json: return_message, status: :ok
    end

  end

  # Add route for specific channels to their own action under the channels collection.
  # When there is no route, it defaults to the create action.
  def create
    channel = params[:channel_id]
    message = "Analyst Console recieved unknown (unrouted) message, on channel #{channel.inspect}"

    Rails.logger.warn(message)

    render plain: message,
           status: :bad_request
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
    #TODO: use stronger permitting here eventually
    params.require(:message).permit!
  end

  def talos_intelligence_params
    params.require(:message)
  end

  def attachments_params
    params.require(:message).permit(attachments: [:file_name,:url,:location,:file_type_name])
  end
end
