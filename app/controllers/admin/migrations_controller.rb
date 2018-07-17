class Admin::MigrationsController < Admin::HomeController
  load_and_authorize_resource class: 'Admin'

  def index
    @migrations = ActiveRecord::Base.connection.execute("select version from schema_migrations order by version")
  end
end
