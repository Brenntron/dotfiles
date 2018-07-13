module API
  module V1
    module Escalations
      module Webcat
        class ComplaintEntries < Grape::API
          include API::V1::Defaults

          resource "escalations/webcat/complaint_entries" do

            desc 'get all complaint entries'
            params do
            end

            get "" do
              json_packet = []
              complaint_entries = ComplaintEntry.all
              if complaint_entries
                complaint_entries.each do |complaint_entry|
                  complaint_entry_packet = {}
                  complaint_entry_packet[:age] = ComplaintEntry.what_time_is_it((Time.now - complaint_entry.created_at).to_i)
                  complaint_entry_packet[:age_int] = (Time.now - complaint_entry.created_at).to_i
                  complaint_entry_packet[:complaint_id] = complaint_entry.complaint.id
                  complaint_entry_packet[:entry_id] = complaint_entry.id

                  complaint_entry_packet[:assigned_to] = complaint_entry.user&.display_name
                  complaint_entry_packet[:status] = complaint_entry.status
                  complaint_entry_packet[:created_at] = complaint_entry.created_at.strftime('%Y-%m-%d %H:%M:%S')
                  complaint_entry_packet[:customer_name] = complaint_entry.complaint&.customer&.name # Customer name

                  complaint_entry_packet[:category] = complaint_entry.category

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
                error = "There was an error when attempting to take entry, no entry was taken.-> #{e.message}"
                {:error => error}.to_json
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
                error = "There was an error when attempting to take entry, no entry was taken.-> #{e.message}"
                {:error => error}.to_json
              end
              {name:current_user.display_name}.to_json
            end

          end
        end
      end
    end
  end
end
