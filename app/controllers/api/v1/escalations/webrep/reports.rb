module API
  module V1
    module Escalations
      module Webrep
        class Reports < Grape::API
          include API::V1::Defaults

          resource "escalations/webrep/reports" do
            before do
              PaperTrail.whodunnit = current_user.id if current_user.present?
            end
            desc 'Open Tickets Report Table'
            params do
              requires :from, type: String
              requires :to, type: String
              requires :users, type: Array[Integer], desc: "array of user ids to apply to the report"
            end

            get "open_tickets_report" do
              authorize!(:index, Dispute)

              report_data = Dispute.open_tickets_report(params[:users], params[:from], params[:to])

              response_data = {:status => "success", :data => report_data}

              response_data.to_json

            end

            desc 'Closed Tickets Report Table'
            params do
              requires :from, type: String
              requires :to, type: String
              requires :users, type: Array[Integer], desc: "array of user ids to apply to the report"
            end

            get "closed_tickets_report" do
              authorize!(:index, Dispute)

              report_data = Dispute.closed_tickets_report(params[:users], params[:from], params[:to])

              response_data = {:status => "success", :data => report_data}

              response_data.to_json

            end


          end
        end
      end
    end
  end
end
