class Admin::MorselsController < Admin::HomeController
  load_and_authorize_resource

  before_action :set_scheduled_task, only: [:destroy]


  def index
    @morsels = Morsel.order(updated_at: :desc)
  end

  def show
    @morsel = Morsel.find(params[:id])
  end

end
