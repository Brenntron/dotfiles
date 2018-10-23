class Escalations::Webrep::RootController < ApplicationController
  def index
    redirect_to escalations_webrep_disputes_path
  end
end
