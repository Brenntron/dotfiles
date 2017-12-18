module API::V2::ActiveModelDefaults
  extend ActiveSupport::Concern

  included do
    include Defaults

    default_format :json
    format :json
    formatter :json, Grape::Formatter::ActiveModelSerializers
  end
end
