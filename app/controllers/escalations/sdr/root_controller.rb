class Escalations::Sdr::RootController < ApplicationController
  def index
    redirect_to escalations_sdr_disputes_path
  end
end
