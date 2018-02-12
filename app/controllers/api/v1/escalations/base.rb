module API
  module V1
    module Escalations
      class Base < Grape::API
        include API::V1::Defaults

        mount API::V1::Escalations::Bugs
        mount API::V1::Escalations::Attachments

      end
    end
  end
end
