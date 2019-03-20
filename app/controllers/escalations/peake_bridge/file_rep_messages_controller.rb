class Escalations::PeakeBridge::FileRepMessagesController < ApplicationController
  # skip_before_action :require_login

  def create
    file_rep = FileRep.where(file_rep_name: file_rep_params[:file_rep_name]).first
    success_status =
        if file_rep
          file_rep.update(file_rep_params)
        else
          file_rep.create(file_rep_params)
        end
    if success_status
      Bridge::GenericAck.new(sender_params, addressee: envelope_params[:sender]).post
      render plain: 'successfully created file rep', status: :ok
    else
      error_messages = file_rep.errors.full_messages.join('; ')
      render plain: "Error(s) creating file rep -- #{error_messages}", status: :internal_server_error
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
    params.require(:message).require(:file_rep).permit(:file_rep_name, :sha256_checksum, :email)
  end
end
