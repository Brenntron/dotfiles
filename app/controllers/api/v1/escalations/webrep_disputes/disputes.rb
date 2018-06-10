module API
  module V1
    module Escalations
      module WebrepDisputes
        class Disputes < Grape::API
          include API::V1::Defaults

          resource "escalations/webrep_disputes/disputes" do
            
            desc 'get all disputes'
            params do
            end

            get "" do

              json_packet = []

              disputes = Dispute.all

              disputes.each do |dispute|
                dispute_packet = {}
                dispute_packet[:id] = dispute.id
                dispute_packet[:case_number] = dispute.case_number
                dispute_packet[:customer_name] = dispute.customer_name
                dispute_packet[:customer_company_name] = dispute.customer_company_name
                dispute_packet[:status] = dispute.status
                dispute_packet[:assigned_to] = dispute.assigned_to
                dispute_packet[:actions] = "<a href='/escalations/webrep/disputes/#{dispute.id}'>edit</a>"

                json_packet << dispute_packet
              end
              {:status => "success", :data => json_packet}.to_json

            end

            desc 'update a dispute'
            params do
            end

            put ":id" do

            end

            desc 'delete a dispute'
            params do
            end

            delete "" do

            end

          end
        end
      end
    end
  end
end
