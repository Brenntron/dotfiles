module API
  module V1
    module Escalations
      module Webcat
        class Complaints < Grape::API
          include API::V1::Defaults

          resource "escalations/webcat/complaints" do

            desc 'get all complaints'
            params do
            end

            get "" do

              json_packet = []

              complaints = Complaint.all
              if complaints
                complaints.each do |complaint|
                  complaint_packet = {}
                  complaint_packet[:id] = complaint.id
                  complaint_packet[:tag] = complaint.tag
                  complaint_packet[:description] = complaint.description
                  complaint_packet[:submission_type] = complaint.submission_type
                  complaint_packet[:submitter_type] = complaint.submitter_type
                  complaint_packet[:assigned_to] = complaint.user_id
                  complaint_packet[:status] = complaint.status
                  complaint_packet[:created_at] = complaint.created_at.strftime('%Y-%m-%d %H:%M:%S')
                  complaint_packet[:customer_name] = complaint.customer.name # Customer name
                  complaint_packet[:complaint_entries] = complaint.complaint_entries
                  complaint_packet[:complaint_entries_count] = complaint.complaint_entries.count

                  complaint_packet[:complaint_entry_content] = []
                  unless complaint.complaint_entries.empty?
                    complaint.complaint_entries.each do |entry|

                      complaint_packet[:complaint_entry_content].push(entry[:subdomain]) unless entry[:subdomain].nil?
                      complaint_packet[:complaint_entry_content].push(entry[:domain]) unless entry[:domain].nil?
                      complaint_packet[:complaint_entry_content].push(entry[:path]) unless entry[:path].nil?
                      complaint_packet[:complaint_entry_content].push(entry[:resolution]) unless entry[:resolution].nil?
                      complaint_packet[:complaint_entry_content].push(entry[:ip_address]) unless entry[:ip_address].nil?
                      complaint_packet[:complaint_entry_content].push(entry[:uri]) unless entry[:uri].nil?
                    end
                  end
                  complaint_packet[:complaint_entry_preview] = complaint_packet[:complaint_entry_content].first.to_s

                  json_packet << complaint_packet
                end
              end
              {:status => "success", :data => json_packet}.to_json

            end

            desc 'test a url'
            params do
              requires :url, type: String, desc: "URL to be visited"
            end
            get "test_url" do
              response = JSON.parse(Complaint.can_visit_url?(params[:url]))
              throw :error, status: response["status"], message: "#{response["error"]}" if response["status"] != "SUCCESS"
              response
            end


            desc 'update a complaint'
            params do
            end

            put ":id" do

            end

            desc 'delete a complaint'
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
