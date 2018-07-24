class Admin::RulesSyncController < Admin::HomeController
  load_and_authorize_resource class: 'Admin'

  def diagnostics
  end
end
