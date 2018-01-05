# Bundle of Core Defaults with the ActiveModelSerializers
# API calls marshalling (returning) active model records with serializers should include this instead of Defaults
module API::V2::ActiveModelDefaults
  extend ActiveSupport::Concern

  included do
    include Defaults

    default_format :json
    format :json
    formatter :json, Grape::Formatter::ActiveModelSerializers
  end
end
