module API
  module V1
    module Escalations
      class Base < Grape::API
        include API::V1::Defaults

        mount API::V1::Escalations::Bugs
        mount API::V1::Escalations::Attachments
        mount API::V1::Escalations::Webrep::Disputes
        mount API::V1::Escalations::Webrep::DisputeEmails
        mount API::V1::Escalations::Webrep::DisputeComments
        mount API::V1::Escalations::Webrep::EmailTemplates
        mount API::V1::Escalations::Webcat::Complaints

      end
    end
  end
end
