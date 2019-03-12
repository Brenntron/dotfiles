class Escalations::PeakeBridge::FileRepMessagesController < ApplicationController
  # skip_before_action :require_login

  def create
    render plain: 'successfully created file rep', status: :ok
  end
end
