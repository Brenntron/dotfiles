module API
  module V1
    class Base < Grape::API

      mount API::V1::Bugs
      mount API::V1::Rules
      mount API::V1::Attachments
      mount API::V1::Users
      mount API::V1::Notes
      mount API::V1::Events
      mount API::V1::SavedSearches
      mount API::V1::Escalations::Base
      mount API::V1::Escalations::Attachments
      mount API::V1::RulehitResolutionMailerTemplates

    end
  end
end
