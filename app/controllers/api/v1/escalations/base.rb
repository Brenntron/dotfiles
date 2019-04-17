module API
  module V1
    module Escalations
      class Base < Grape::API
        include API::V1::Defaults

        mount API::V1::Escalations::Bugs
        mount API::V1::Escalations::BugzillaRestLogin
        mount API::V1::Escalations::Attachments
        mount API::V1::Escalations::UserPreferences
        mount API::V1::Escalations::FileRep::Research
        mount API::V1::Escalations::FileRep::ReversingLabs
        mount API::V1::Escalations::FileRep::SandboxApi
        mount API::V1::Escalations::FileRep::Disputes
        mount API::V1::Escalations::FileRep::DisputeComments
        mount API::V1::Escalations::Webrep::Disputes
        mount API::V1::Escalations::Webrep::DisputeEmails
        mount API::V1::Escalations::Webrep::DisputeComments
        mount API::V1::Escalations::Webrep::EmailTemplates
        mount API::V1::Escalations::Webrep::Reports
        mount API::V1::Escalations::Webrep::ResolutionMessageTemplates
        mount API::V1::Escalations::Webcat::Complaints
        mount API::V1::Escalations::Webcat::ComplaintEntries
        mount API::V1::Escalations::Webcat::Customers
        mount API::V1::Escalations::Webcat::Clusters
      end
    end
  end
end
