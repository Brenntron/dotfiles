class Escalations::Filerep::RootController < ApplicationController
  def index
    redirect_to escalations_file_rep_disputes_path
  end
end
