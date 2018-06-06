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
                  complaint_packet[:subdomain] = complaint.subdomain
                  complaint_packet[:domain] = complaint.domain
                  complaint_packet[:path] = complaint.path
                  complaint_packet[:status] = complaint.status
                  complaint_packet[:age] = complaint.age
                  complaint_packet[:customer] = complaint.wbrs_score
                  complaint_packet[:url_primary_cat] = complaint.url_primary_cat

                  json_packet << complaint_packet
                end
              end
              {:status => "success", :data => json_packet}.to_json

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
