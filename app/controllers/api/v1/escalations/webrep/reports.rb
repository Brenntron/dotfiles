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
              users = User.where(:id => params[:users])
              report_data = Dispute.closed_tickets_report(users, params[:from], params[:to])

              response_data = {:status => "success", :data => report_data}

              response_data.to_json

            end

            desc 'Ticket Entries Closed By Day Graph'

            params do
              requires :from, type: String
              requires :to, type: String
              requires :user_id, type: Integer, desc: ""
            end

            get "ticket_entries_closed_by_day_report" do
              authorize!(:index, Dispute)

              report_data = Dispute.ticket_entries_closed_by_day_report(params[:user_id], params[:from], params[:to])

              response_data = {:status => "success", :data => report_data}

              response_data.to_json

            end

            params do
              requires :from, type: String
              requires :to, type: String
              requires :user_id, type: Integer, desc: ""
            end

            get 'ticket_time_to_close_report' do
              authorize!(:index, Dispute)

              report_data = Dispute.ticket_time_to_close_report(params[:user_id], params[:from], params[:to])

              response_data = {:status => "success", :data => report_data}

              response_data.to_json
            end

            params do
              requires :from, type: String
              requires :to, type: String
              requires :user_id, type: Integer, desc: ""
              requires :submission_types, type: Array[String]
            end

            get 'closed_ticket_entries_by_resolution_report' do
              authorize!(:index, Dispute)

              report_data = Dispute.closed_ticket_entries_by_resolution_report(params[:user_id], params[:from], params[:to], params[:submission_types])

              response_data = {:status => "success", :data => report_data}

              response_data.to_json
            end

            params do
              requires :from, type: String
              requires :to, type: String
              requires :users, type: Array[Integer], desc: ""
            end

            get 'ticket_entries_closed_by_ticket_owner_report' do
              authorize!(:index, Dispute)
              users = User.where(:id => params[:users])
              report_data = Dispute.ticket_entries_closed_by_ticket_owner(users, params[:from], params[:to])

              response_data = {:status => "success", :data => report_data}

              response_data.to_json
            end

            params do
              requires :from, type: String
              requires :to, type: String
              requires :users, type: Array[Integer], desc: ""
            end

            get 'average_time_to_close_tickets_by_ticket_owner_report' do
              authorize!(:index, Dispute)
              users = User.where(:id => params[:users])
              report_data = Dispute.average_time_to_close_tickets_by_ticket_owner(users, params[:from], params[:to])

              response_data = {:status => "success", :data => report_data}

              response_data.to_json
            end

          end
        end
      end
    end
  end
end
