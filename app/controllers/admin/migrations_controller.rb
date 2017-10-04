module Admin
  class MigrationsController < ApplicationController
    def index
      @migrations = ActiveRecord::Base.connection.execute("select version from schema_migrations order by version")
    end
  end
end
