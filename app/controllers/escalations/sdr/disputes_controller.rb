class Escalations::Sdr::DisputesController < ApplicationController
  def show
    @dispute = SenderDomainReputationDispute.where(id: params[:id]).first
    @versioned_items = @dispute.compose_versioned_items
  end
end
