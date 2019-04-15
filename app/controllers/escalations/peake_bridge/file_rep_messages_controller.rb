class Escalations::PeakeBridge::FileRepMessagesController < ApplicationController
  # skip_before_action :require_login

  def create

    response = FileReputationDispute.process_bridge_payload(file_rep_params)

    if response[:success]
      sender_params[:addressee_id] = file_rep.id
      sender_params[:addressee_status] = file_rep.status
      Bridge::GenericAck.new(sender_params, addressee: envelope_params[:sender]).post
      render plain: response[:message], status: :ok
    else
      error_messages = file_rep.errors.full_messages.join('; ')
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
    params.require(:message).require(:file_rep).permit(:file_name, :sha256_hash, :disposition_suggested, :file_size, :email, :customer)
  end
end
