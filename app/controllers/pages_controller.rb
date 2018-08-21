class PagesController < ApplicationController

  def index
    if current_user
      redirect_to escalations_user_path(current_user)
    end
  end
end