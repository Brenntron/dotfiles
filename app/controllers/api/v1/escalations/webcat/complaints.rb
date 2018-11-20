module API
  module V1
    module Escalations
      module Webcat
        class Complaints < Grape::API
          include API::V1::Defaults

          resource "escalations/webcat/complaints" do

            before do
              PaperTrail.request.whodunnit = current_user.id if current_user.present?
            end

            desc 'get all complaints'
            params do
            end

            get "" do
              authorize!(:index, Complaint)

              json_packet = []

              complaints = Complaint.all
              if complaints
                complaints.each do |complaint|
                  complaint_packet = {}
                  complaint_packet[:age] = Complaint.what_time_is_it((Time.now - complaint.created_at).to_i)
                  complaint_packet[:id] = complaint.id
                  complaint_packet[:entry_id] = complaint.id
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

            desc 'create a complaint'
            params do
              requires :ips_urls, type: String, desc: 'List of URLs to create entries'
              requires :description, type: String, desc: 'Description of new complaint'
              optional :customer, type: String, desc: 'Customer related to new complaint'
              optional :tags, type: Array, desc: 'Array of tags to be associated with the new complaint'
            end

            post "" do
              Complaint.create_action(bugzilla_session,
                                      permitted_params[:ips_urls],
                                      permitted_params[:description],
                                      permitted_params[:customer],
                                      permitted_params[:tags])
              {:status => 'success'}.to_json
            end

            desc 'test a url'
            params do
              requires :url, type: String, desc: "URL to be visited"
            end
            get "test_url" do
              # TODO determine access control policy for test_url
              response = JSON.parse(Complaint.can_visit_url?(params[:url]))
              throw :error, status: response["status"], message: "#{response["error"]}" if response["status"] != "SUCCESS"
              response
            end


            desc 'update a complaint'
            params do
            end

            put ":id" do
              # TODO access control when this is implemented
            end

            desc 'delete a complaint'
            params do
            end

            delete "" do
              # TODO access control when this is implemented
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
              # TODO determine access control policy for mark_for_commit
              ComplaintMarkedCommit.mark_for_commit(permitted_params['complaint_entry_ids'],
                                                    permitted_params['category_list'],
                                                    user: current_user,
                                                    comment: permitted_params['comment'])
              true
            end

            desc 'commit marked'
            post 'commit_marked' do
              # TODO determine access control policy for mark_for_commit
              ComplaintMarkedCommit.commit_marked(user: current_user)
              true
            end

            desc 'categorize url without complaint'
            params do
              requires :data, type: Hash, desc: "Hash of urls and categories to create prefixes on"
            end
            post 'cat_new_url' do
              std_api_v2 do
                params["data"].each do |item, prefix|
                  if prefix["url"].present?
                    Complaint.commit_without_complaint(ip_or_uri: prefix["url"],
                                                       categories_string: prefix["cats"].join(','),
                                                       description: '',
                                                       user: current_user.email,
                                                       bugzilla_session: bugzilla_session)

                  end
                end
              end
            end

            desc 'categorize multiple urls without complaint'
            params do
              requires :urls, type: Array[String], desc: "URLS for categorization"
              requires :cats, type: Array[String], desc: "Categories to apply"
            end
            post 'multi_cat_new_url' do
              std_api_v2 do
                permitted_params['urls'].each do |prefix|
                  Complaint.commit_without_complaint(ip_or_uri: prefix,
                                                     categories_string: permitted_params["cats"].join(','),
                                                     description: '',
                                                     user: current_user.email,
                                                     bugzilla_session: bugzilla_session)
                end
              end
              render json: 'Success'
            end

            post 'fetch' do
              std_api_v2 do
                response = Bridge::DirectRequest.poll('talos-intelligence')
                raise "Error code #{response.code} fetching complaints." unless 400 > response.code
              end
            end

            params do
              requires :urls, type: Array[String]
            end

            post 'lookup_prefix' do
              prefix_ids = {}

              permitted_params['urls'].each_with_index do |param, position|
                prefix_record = Wbrs::Prefix.where(:urls => [param])
                if !prefix_record.empty? && prefix_record.first.is_active == 1
                  prefix_ids[position + 1] = prefix_record.first.prefix_id
                else
                  prefix_ids[position + 1 ] = nil
                end
              end

              responses = {}
              response_json = {}

              prefix_ids.each do |position, prefix_id|
                if prefix_id != nil
                  responses[position]= (Wbrs::Prefix.post_request(path: '/v1/cat/rules/get', body: { prefix_ids: [prefix_id] }))
                end
              end

              responses.each do |position, response|
                response_json[position] = JSON.parse(response.body)
              end

              render json: response_json
            end

            params do
              requires :urls, type: Array[String], desc: "Drops categories on URLS"
            end

            post 'drop_current_categories' do
              prefix_ids = []
              response = []

              urls = permitted_params['urls'].compact

              urls.each do |url|
                if url == ''
                  urls.delete('')
                end
              end

              urls.each do |param|
                if !Wbrs::Prefix.where(:urls => [param]).empty?
                  prefix_ids.push(Wbrs::Prefix.where(:urls => [param]).first.prefix_id)
                end
              end

              prefix_ids.each do |prefix_id|
                response = Wbrs::Prefix.disable(prefix_id, current_user.email)
              end

              render json: response
            end

            post 'fetch_wbnp_data' do
              std_api_v2 do

                Complaint.get_latest_wbnp_complaints
                {:status => "success"}.to_json

              end
            end

            params do
              requires :uri, type: String
              requires :complaint_entry_id, type: Integer
            end

            post 'update_uri' do
              std_api_v2 do
                authorize!(:update, DisputeEntry)
                complaint_entry = ComplaintEntry.find(permitted_params[:complaint_entry_id])
                complaint_entry.update_uri(permitted_params[:uri])
              end
            end

          end
        end
      end
    end
  end
end
