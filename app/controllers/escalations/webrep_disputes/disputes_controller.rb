class Escalations::WebrepDisputes::DisputesController < ApplicationController

  before_action :require_login

  def index
  end

  def show
    @dispute = Dispute.find(params[:id])
  end

  def update
  end

  def dashboard

  end

  def single

  end

end
