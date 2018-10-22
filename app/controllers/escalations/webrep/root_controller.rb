class Escalations::Webrep::RootController < ApplicationController
  def index
    redirect_to escalations_webrep_tickets_path
  end
end
