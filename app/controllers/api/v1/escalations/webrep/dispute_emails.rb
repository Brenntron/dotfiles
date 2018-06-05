module API
  module V1
    module Escalations
      module Webrep
        class DisputeEmails < Grape::API
          include API::V1::Defaults

          resource "escalations/webrep/dispute_emails" do

            desc "get a dispute email"
            params do
              requires :id, type: String, desc: "ID of the attachment"
            end
            get ":id", root: "dispute_email" do
              DisputeEmail.where(id: permitted_params[:id])
            end

          end
        end
      end
    end
  end
end