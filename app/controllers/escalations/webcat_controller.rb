class Escalations::WebcatController < ApplicationController
  before_action :require_login
  before_action :dashboard_metrics

  def dashboard_metrics
    @secHub_1 = 62
    @secHub_2 = 2827
    @ss = 0
    @int_1 = 0
    @int_2 = 0
    @wbnp = 37

    @pending = 25
    @new = 25
    @overdue = 0
  end
end