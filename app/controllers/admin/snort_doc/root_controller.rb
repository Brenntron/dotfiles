class Admin::SnortDoc::RootController < ApplicationController
  load_and_authorize_resource class: 'Admin'

  def index
  end
end
