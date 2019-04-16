class Escalations::PeakeBridge::FileRepMessagesController < ApplicationController
  # skip_before_action :require_login

  def create

    file_rep_params[:bugzilla_rest_session] = bugzilla_rest_session
    response = FileReputationDispute.process_bridge_payload(file_rep_params, customer_params)

    if response[:success]
      sender_params[:addressee_id] = file_rep.id
      sender_params[:addressee_status] = file_rep.status
      Bridge::GenericAck.new(sender_params, addressee: envelope_params[:sender]).post
      render plain: response[:message], status: :ok
    else
      render plain: response[:message], status: :internal_server_error
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
