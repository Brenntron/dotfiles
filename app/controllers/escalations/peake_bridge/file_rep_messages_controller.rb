class Escalations::PeakeBridge::FileRepMessagesController < ApplicationController
  # skip_before_action :require_login

  def create

    return_message = "Can't even"
    return_success = false

    message_payload = file_rep_params
    message_payload[:bugzilla_rest_session] = bugzilla_rest_session
    new_dispute = FileReputationDispute.process_bridge_payload(message_payload, customer_params)

    if new_dispute.new_record?
      error_messages = new_dispute.errors.full_messages.join('; ')
      expanded_message = "Error(s) creating file rep -- #{error_messages}"
      return_message = '{ "success": true, "message": "' + expanded_message +'" }'
      Rails.logger.error(return_message)
    else
      return_success = true
      return_message = '{ "success": true, "message": "successfully created file rep" }'

      new_dispute.ack_create(envelope_params, sender_params)
    end

    if return_success
      render plain: return_message, status: :ok
    else
      render plain: return_message, status: :internal_server_error
    end
  end

  private

  def envelope_params
    params.require(:envelope).permit(:channel, :sender, :addressee)
  end

  def sender_params
    params.require(:message).require(:sender_data).permit!
  end

  def file_rep_params
    params.require(:message).require(:file_rep).permit(:sha256_hash, :file_name, :file_size, :sample_type,
                                                       :disposition_suggested, :source, :platform)
  end

  def customer_params
    params.require(:message).require(:file_rep).fetch(:customer, {}).permit(:email, :name, :company_name)
  end

  def bugzilla_rest_session
    BugzillaRest::Session.default_session
  end
end
