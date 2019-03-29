class Escalations::Filerep::RootController < ApplicationController
  def index
    redirect_to escalations_filerep_disputes_path
  end
end
