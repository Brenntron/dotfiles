class Escalations::Sdr::DisputesController < ApplicationController
  def show
    @dispute = SenderDomainReputationDispute.where(id: params[:id]).first
  end
end
