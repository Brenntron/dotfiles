module Admin
  class MigrationsController < ApplicationController
    before_action { authorize!(:manage, Admin) }

    def index
      @migrations = ActiveRecord::Base.connection.execute("select version from schema_migrations order by version")
    end
  end
end
