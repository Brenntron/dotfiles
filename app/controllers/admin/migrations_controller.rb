class Admin::MigrationsController < Admin::HomeController

  def index
    @migrations = ActiveRecord::Base.connection.execute("select version from schema_migrations order by version")
  end
end
