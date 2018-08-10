module API
  module V1
    module Escalations
      module Webcat
        class ComplaintEntries < Grape::API
          include API::V1::Defaults

          resource "escalations/webcat/complaint_entries" do

            desc 'get all complaint entries'
            params do
              optional :filter_by, type: String, desc: 'filter entries by this value'
              optional :self_review, type: Boolean, desc: 'a flag that allows users to review their own categorizations'
              optional :search, type: String, desc: 'search entries by this value'

              optional :customer, type: Hash do
                optional :name, type: String
                optional :email, type: String
                optional :company_name, type: String
              end

              optional :complaint_entries, type: Hash do
                optional :ip_or_uri, type: String
                optional :resolution, type: String
                optional :category, type: String
                optional :status, type: String
                optional :complaint_id, type: Integer
              end
              optional :search_type, type: String
              optional :search_name, type: String
              optional :description, type: String
              optional :submitted_older, type: Date
              optional :submitted_newer, type: Date
              optional :modified_older, type: Date
              optional :modified_newer, type: Date
              optional :channel, type: String
              optional :tags, type: Array
            end

            get "" do
              json_packet = []

              search_type = ComplaintEntry.get_search_type(permitted_params)
              search_name = permitted_params[:search_name] ? permitted_params[:search_name] : nil


              complaint_entries = ComplaintEntry.robust_search(search_type,
                                                               search_name: search_name,
                                                               params: permitted_params,
                                                               user: current_user)


              if complaint_entries
                complaint_entries.each do |complaint_entry|
                  complaint_entry_packet = {}
                  complaint_entry_packet[:age] = ComplaintEntry.what_time_is_it((Time.now - complaint_entry.created_at).to_i)
                  complaint_entry_packet[:age_int] = (Time.now - complaint_entry.created_at).to_i
                  complaint_entry_packet[:complaint_id] = complaint_entry&.complaint.id
                  complaint_entry_packet[:entry_id] = complaint_entry.id

                  complaint_entry_packet[:assigned_to] = complaint_entry.user&.display_name
                  complaint_entry_packet[:status] = complaint_entry.status
                  complaint_entry_packet[:created_at] = complaint_entry.created_at.strftime('%Y-%m-%d %H:%M:%S')
                  complaint_entry_packet[:customer_name] = complaint_entry.complaint&.customer&.name # Customer name

                  complaint_entry_packet[:category] = complaint_entry.url_primary_category
                  complaint_entry_packet[:resolution]= complaint_entry.resolution
                  complaint_entry_packet[:resolution_comment] = complaint_entry.resolution_comment

                  complaint_entry_packet[:subdomain] = complaint_entry.subdomain
                  complaint_entry_packet[:domain] = complaint_entry.domain
                  complaint_entry_packet[:path] = complaint_entry.path
                  complaint_entry_packet[:ip_address] = complaint_entry.ip_address
                  complaint_entry_packet[:wbrs_score] = complaint_entry.wbrs_score
                  complaint_entry_packet[:is_important] = complaint_entry.is_important
                  complaint_entry_packet[:viewable] = complaint_entry.viewable

                  json_packet << complaint_entry_packet
                end
              end
              {:status => "success", :data => json_packet}.to_json

            end


            desc 'update an entry '
            params do
              requires :id, type: Integer, desc:'complaint entry id'
              requires :prefix, type: String, desc: 'the url to categorize'
              requires :categories, type: String, desc: 'a list of categories to assign to this prefix'
              requires :status, type: String, desc: 'setting the status of the entry'
              optional :comment, type: String, desc: 'resolution comment for the customer'
            end
            post 'update'do
              begin
                entry = ComplaintEntry.find(permitted_params['id'])
                entry.change_category( permitted_params['prefix'],permitted_params['categories'],
                                         permitted_params['status'],
                                         permitted_params['comment'],
                                         current_user, "")
              rescue Exception => e
                  return {error:e.message}.to_json
              end
              {status:entry.status, entry_resolution:permitted_params['status']}.to_json
            end
            desc 'update a high telemetry entry'
            params do
              requires :id, type:Integer, desc:'complaint entry id'
              requires :prefix, type:String, desc: 'the url to categorize'
              requires :commit, type: String, desc: 'set this if you want to commit a pending complaint'
              optional :comment, type: String, desc: 'resolution comment for the customer'
            end
            post 'update_pending' do
              begin
                entry = ComplaintEntry.find(permitted_params['id'])
                entry.change_category( permitted_params['prefix'], permitted_params['categories'],
                                    permitted_params['status'],
                                    permitted_params['comment'],
                                    current_user, permitted_params['commit'])
              rescue Exception => e
                return e.message
              end
              {status:entry.status, entry_resolution:permitted_params['commit']}.to_json
            end

            desc 'take entry'
            params do
              requires :complaint_entry_ids, type: Array[Integer], desc: 'ComplaintEntry ids'
            end
            post 'take_entry' do
              begin
                permitted_params['complaint_entry_ids'].each do |id|
                  ComplaintEntry.find(id).take_complaint(current_user)
                end
              rescue Exception => e
                Rails.logger.error "Failed to take entry: error=> #{e.message}"
                error = "#{e.message}"
                return {:error => error}.to_json
              end
              {name:current_user.display_name}.to_json
            end
            desc 'return entry'
            params do
              requires :complaint_entry_ids, type: Array[Integer], desc: 'ComplaintEntry ids'
            end
            post 'return_entry' do
              begin
                permitted_params['complaint_entry_ids'].each do |id|
                  ComplaintEntry.find(id).return_complaint(current_user)
                end
              rescue Exception => e
                Rails.logger.error "Failed to take entry: error=> #{e.message}"
                error = "#{e.message}"
                return {:error => error}.to_json
              end
              {name:current_user.display_name}.to_json
            end

            get ':complaint_entry_id/screenshot' do
              std_api_v2 do
                entry = ComplaintEntry.find(params[:complaint_entry_id])
                return { image_data: '' }.to_json unless entry
                record = entry.complaint_entry_screenshot
                return { image_data: '' }.to_json unless record
                return { image_data: Base64.encode64(record.screenshot) }.to_json
              end
            end
          end
        end
      end
    end
  end
end
