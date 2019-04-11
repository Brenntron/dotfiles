class Escalations::PeakeBridge::FileRepMessagesController < ApplicationController
  # skip_before_action :require_login

  def create
    file_rep = FileReputationDispute.where(file_name: file_rep_params[:file_rep_name]).first
    file_rep ||= FileReputationDispute.new

    if file_rep_params[:sha256_checksum].present?
      threatgrid_response = Threatgrid::Search.query(file_rep_params[:sha256_checksum])

      threat_score = threatgrid_response['threat_score']
      threatgrid_private = threatgrid_response['threatgrid_private']
    else
      threat_score = nil
      threatgrid_private = nil
    end

    attributes = {
        file_name: file_rep_params[:file_rep_name],
        sha256_hash: file_rep_params[:sha256_checksum],
        source: file_rep_params[:email],
        status: 'NEW',
        disposition_suggested: file_rep_params[:disposition_suggested],
        threatgrid_score: threat_score,
        threatgrid_private: threatgrid_private
    }
    file_rep.assign_attributes(attributes)

    if file_rep.save
      sender_params[:addressee_id] = file_rep.id
      sender_params[:addressee_status] = file_rep.status
      Bridge::GenericAck.new(sender_params, addressee: envelope_params[:sender]).post
      render plain: '"successfully created file rep"', status: :ok
    else
      error_messages = file_rep.errors.full_messages.join('; ')
      render plain: "\"Error(s) creating file rep -- #{error_messages}\"", status: :internal_server_error
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
    params.require(:message).require(:file_rep).permit(:file_rep_name, :sha256_checksum, :email, :disposition_suggested)
  end
end
