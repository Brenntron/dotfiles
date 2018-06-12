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

                # dispute_packet[:case_number] = dispute.case_number
                # dispute_packet[:case_number] = sprintf '%08d', dispute.id
                dispute_packet[:submitter_name] = dispute.customer_name
                dispute_packet[:submitter_org] = dispute.org_domain # should be: dispute.customer_company_name
                dispute_packet[:submitter_domain] = dispute.org_domain # should be: dispute.customer_company_name
                dispute_packet[:dispute_domain] = dispute.org_domain
                unless dispute.dispute_entries.empty?
                  unless dispute.dispute_entries.first[:hostname].nil?
                    dispute_packet[:dispute_domain] = dispute.dispute_entries.first[:hostname]
                  end
                end
                dispute_packet[:status] = dispute.status.upcase
                dispute_packet[:assigned_to] = dispute.assignee
                dispute_packet[:actions] = "<a href='/escalations/webrep/disputes/#{dispute.id}'>edit</a>"
                dispute_packet[:case_number] = "<a href='/escalations/webrep/disputes/#{dispute.id}'>" + ( sprintf '%08d', dispute.id ).to_s + "</a>"

                dispute_packet[:case_opened_at] = dispute.case_opened_at.strftime('%Y-%m-%d %H:%M:%S')
                dispute_packet[:case_age] = dispute.dispute_age
                # dispute_packet[:suggested_disposition] = 'Malicious: Phishing'
                dispute_packet[:suggested_disposition] = dispute.suggested_d
                dispute_packet[:priority] = "P" + (( dispute.id % 3 ) + 1).to_s # should be: dispute.priority
                dispute_packet[:source] = dispute.ticket_source.nil? ? "Bugzilla" : dispute.ticket_source
                dispute_packet[:source_id] = dispute.ticket_source_key
                dispute_packet[:source_type] = dispute.ticket_source_type

                dispute_packet[:wbrs_score] = ''
                unless dispute.dispute_entries.empty?
                  if dispute.dispute_entries.first[:score_type] == "WBRS"
                    dispute_packet[:wbrs_score] = dispute.dispute_entries.first[:score].to_s
                  end
                end

                json_packet << dispute_packet
              end
              {:status => "success", :data => json_packet}.to_json

            end

            get "my" do

              json_packet = []

              disputes = Dispute.where("id like '20%18'") # random subset, for now

              disputes.each do |dispute|
                dispute_packet = {}
                dispute_packet[:id] = dispute.id

                dispute_packet[:customer_name] = dispute.customer_name
                dispute_packet[:customer_company_name] = dispute.org_domain # should be: dispute.customer_company_name
                dispute_packet[:status] = dispute.status.upcase
                dispute_packet[:assigned_to] = dispute.assignee
                dispute_packet[:actions] = "<a href='/escalations/webrep/disputes/#{dispute.id}'>edit</a>"
                dispute_packet[:case_number] = "<a href='/escalations/webrep/disputes/#{dispute.id}'>" + ( sprintf '%08d', dispute.id ).to_s + "</a>"

                dispute_packet[:case_opened_at] = dispute.case_opened_at.strftime('%Y-%m-%d %H:%M:%S')
                dispute_packet[:case_age] = dispute.dispute_age
                # dispute_packet[:suggested_disposition] = 'Malicious: Phishing'
                dispute_packet[:suggested_disposition] = dispute.suggested_d
                dispute_packet[:priority] = "P" + (( dispute.id % 3 ) + 1).to_s # should be: dispute.priority
                dispute_packet[:source] = dispute.ticket_source
                dispute_packet[:source_id] = dispute.ticket_source_key

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
