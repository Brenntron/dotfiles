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

            # 'complaint_entry_ids': entry_ids
            # 'category_list': $('#complaint_id_x_categories').val()
            # 'comment': $('#complaint_id_x_comment').val()
            desc 'mark for commit'
            params do
              requires :complaint_entry_ids, type: Array[Integer], desc: 'ComplaintEntry ids'
              requires :category_list, type: String, desc: 'Comma separated list of threat category names'
              requires :comment, type: String
            end
            post 'mark_for_commit' do
              ComplaintMarkedCommit.mark_for_commit(permitted_params['complaint_entry_ids'],
                                                    permitted_params['category_list'],
                                                    user: current_user,
                                                    comment: permitted_params['comment'])
              true
            end

            desc 'commit marked'
            post 'commit_marked' do
              ComplaintMarkedCommit.commit_marked(user: current_user)
              true
            end
          end
        end
      end
    end
  end
end
