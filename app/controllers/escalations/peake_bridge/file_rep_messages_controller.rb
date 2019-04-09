class Escalations::PeakeBridge::FileRepMessagesController < ApplicationController
  # skip_before_action :require_login

  def create
    file_rep = FileReputationDispute.where(file_name: file_rep_params[:file_rep_name]).first
    file_rep ||= FileReputationDispute.new

    if file_rep.sha256_hash.present?
      api_response = Threatgrid::ThreatScore.get_threat_score(file_rep.sha256_hash)
      threat_score = api_response['threat_score']
      threat_grid_private = api_response['threat_grid_private']
    end

    attributes = {
        file_name: file_rep_params[:file_rep_name],
        sha256_hash: file_rep_params[:sha256_checksum],
        source: file_rep_params[:email],
        status: 'NEW',
        threat_score: threat_score,
        threat_grid_private: threat_grid_private
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
    params.require(:message).require(:file_reputation_dispute).permit(:file_rep_name, :sha256_checksum, :email)
  end
end
