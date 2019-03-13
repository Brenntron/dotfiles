class Escalations::PeakeBridge::FileRepMessagesController < ApplicationController
  # skip_before_action :require_login

  def create
    render plain: 'successfully created file rep', status: :ok
  end

  private

  def envelope_params
    params.require(:envelope).permit(:channel, :sender, :addressee)
  end

end
