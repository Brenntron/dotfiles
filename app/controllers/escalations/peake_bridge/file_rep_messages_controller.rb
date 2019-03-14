class Escalations::PeakeBridge::FileRepMessagesController < ApplicationController
  # skip_before_action :require_login

  def create
    file_rep = FileRep.new(file_rep_params)
    if file_rep.save
      render plain: 'successfully created file rep', status: :ok
    else
      error_messages = file_rep.errors.full_messages.join('; ')
      render plain: "Error(s) creating file rep -- #{error_messages}", status: :ok
    end
  end

  private

  def file_rep_params
    params.require(:message).permit(:file_rep_name, :sha256_checksum, :email)
  end
end
