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
        message_payload[:bugzilla_rest_session] = bugzilla_rest_session
        message_payload[:current_user] = current_user

        if self.class.threaded?
          Thread.new do
            obj_type.constantize.process_bridge_payload(message_payload)
          end
        else
          obj_type.constantize.process_bridge_payload(message_payload)
        end

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


  # defined so tests can stub to return false.
  def self.threaded?
    true
  end

  def bugzilla_rest_session
    BugzillaRest::Session.new(api_key: Rails.configuration.bugzilla_api_key)
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
