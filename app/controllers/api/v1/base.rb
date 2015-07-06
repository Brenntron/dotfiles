require "grape-swagger"
module API
  module V1
    class Base < Grape::API

      mount API::V1::Bugs
      mount API::V1::Rules
      mount API::V1::Exploits
      mount API::V1::Attachments
      mount API::V1::Users
      mount API::V1::Notes
      mount API::V1::Events
      mount API::V1::References


      add_swagger_documentation(
          api_version: "v1",
          hide_documentation_path: true,
          mount_path: "/api/v1/swagger_doc",
          hide_format: true
      )

    end
  end
end
