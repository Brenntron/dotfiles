module API
  module V1
    module Escalations
      module Webrep
        class Disputes < Grape::API
          include API::V1::Defaults

          resource "escalations/webrep/disputes" do
            before do
              PaperTrail.whodunnit = current_user.id if current_user.present?
            end
            desc 'get all disputes'
            params do
              optional :search_type, type: String
              optional :search_name, type: String
              optional :value, type: String
              optional :case_id, type: Integer
              optional :org_domain, type: String
              optional :case_owner_username, type: String
              optional :status, type: String
              optional :priority, type: String
              optional :resolution, type: String
              optional :submitter_type, type: String
              optional :submitted_older, type: Date
              optional :submitted_newer, type: Date
              optional :age_older, type: String
              optional :age_newer, type: String
              optional :modified_older, type: Date
              optional :modified_newer, type: Date
              optional :customer, type: Hash do
                optional :name, type: String
                optional :email, type: String
                optional :company_name, type: String
              end
              optional :dispute_entries, type: Hash do
                optional :ip_or_uri, type: String
                optional :suggested_disposition, type: String
              end
            end

            get "" do
              authorize!(:index, Dispute)

              disputes = Dispute.robust_search(permitted_params['search_type'],
                                               search_name: permitted_params['search_name'],
                                               params: permitted_params,
                                               user: current_user).includes(:user, :dispute_entries => [:dispute_rule_hits])  # [but inside]
              title = Dispute.robust_search_title(permitted_params['search_type'], search_name: permitted_params['search_name'])
              json_packet = Dispute.to_data_packet(disputes)

              response_data = {status: "success", title: title, data: json_packet}
              if 'advanced' == permitted_params['search_type']
                if permitted_params['search_name'].present?
                  search_name = permitted_params['search_name']
                  response_data['search_name'] = search_name
                  named_search = NamedSearch.where(user: current_user, name: search_name).first
                  response_data['search_id'] = named_search&.id
                end
              end
              response_data.to_json

            end

            desc 'update a dispute'
            params do
            end

            put ":id" do
              # TODO access control when this is implmented
            end

            desc 'delete a dispute'
            params do
            end

            delete "" do
              # TODO access control when this is implmented
            end

            desc "Add new dispute entry"
            params do
              requires :uri, type: String, desc: "IP address or host name to add"
              requires :dispute_id, type: Integer, desc: "ID of the dispute to add the entry to"
            end
            post "new_adhoc_entry" do
              json_packet = []

              entry = DisputeEntry.new(:dispute_id => params[:dispute_id], user_id => current_user.id)

              is_ip_address = !!(params[:uri]  =~ Resolv::IPv4::Regex)

              if is_ip_address
                entry.ip_address = params[:uri]
              else
                entry.uri = params[:uri]
              end
              binding.pry
              entry.save!

              json_packet << entry

              {:status => "success", :data => json_packet}.to_json if entry.save?
            end

            desc "Change assignee of a group of dispute IDs"
            params do
              requires :dispute_ids, type: Array[Integer], desc: "analyst-console database id"
              requires :new_assignee, type: Integer, desc: "User ID of new assignee"
            end
            post "change_assignee" do
              json_packet = []
              params[:dispute_ids].each do |dispute|
                Dispute.where(id: dispute).update_all(user_id: params[:new_assignee])
                d = Dispute.find_by(id: dispute)

                raise "This record changed while you were editing. To continue this operation anyway, reload the page and make your assignment again." unless d.user_id == params[:new_assignee]
                json_packet << d
              end
              {:status => "success", :data => json_packet}.to_json
            end

            desc "Remove assignee from a group of dispute IDs (revert to vrtincoming)"
            params do
              requires :dispute_ids, type: Array[Integer], desc: "analyst-console database id"
            end
            post "unassign_all" do
              json_packet = []
              vrt = User.where(email: 'vrt-incoming@sourcefire.com').first
              params[:dispute_ids].each do |dispute|
                Dispute.where(id: dispute).update_all(user_id: vrt.id)
                d = Dispute.find_by(id: dispute)

                raise "This record changed while you were editing. To continue this operation anyway, reload the page and make your assignment again." unless d.user_id == vrt.id
                json_packet << d
              end
              {:status => "success", :data => json_packet}.to_json
            end

            desc "Adjust a WL/BL entry"
            params do
              requires :dispute_entry_ids, type: Array[Integer], desc: "analyst-console database id"
              requires :trgt_list, type: Array[String], desc: "type of WL/BL"
              optional :thrt_cats, type: Array[String], desc: "threat categories"
              requires :note, type: String, desc: "note"
            end
            post "entry_wlbl" do
              authorize!(:update, Wbrs::ManualWlbl)
              Wbrs::ManualWlbl.adjust_entries_from_params(permitted_params, username: current_user.cvs_username)
            end

            desc "Adjust a WL/BL entry"
            params do
              requires :dispute_ids, type: Array[Integer], desc: "analyst-console database id"
              requires :trgt_list, type: Array[String], desc: "type of WL/BL"
              optional :thrt_cats, type: Array[String], desc: "threat categories"
              requires :note, type: String, desc: "note"
            end
            post "ticket_wlbl" do
              authorize!(:update, Wbrs::ManualWlbl)
              Wbrs::ManualWlbl.adjust_tickets_from_params(permitted_params, username: current_user.cvs_username)
            end

            desc "Adjust a Reptool Bl entry"
            params do
              requires :action, type: String, desc: 'activate or expire'
              requires :dispute_entry_ids, type: Array[Integer], desc: "analyst-console database id"
              #requires :entries, type: Array[String], desc: "urls"
              requires :classifications, type: Array[String], desc: "classifications"
              requires :comment, type: String, desc: "comment"
            end
            post "reptool_bl" do
              RepApi::Blacklist.adjust_from_params(permitted_params, username: current_user.cvs_username)
              true
            end

            desc "Sync data for all dispute entry children"
            params do
              requires :dispute_id
            end
            post "sync_data" do
                
                dispute = Dispute.where({:id => params[:dispute_id]}).first
                dispute.dispute_entries.each do |dispute_entry|

                  dispute_entry.sync_up

                end
                {:status => "success"}.to_json

            end

            delete "searches/:search_name" do
              # TODO determine access control policy for named searches
              search = NamedSearch.where(name: params['search_name'], user: current_user)
              search.destroy_all
              true
            end

            patch 'take_dispute/:dispute_id' do
              std_api_v2 do
                authorize!(:update, Dispute)
                dispute = Dispute.find(params['dispute_id'])
                authorize!(:update, dispute)

                dispute.take_ticket(user: current_user)

                { username: current_user.display_name, dispute_id: dispute.id }
              end
            end

            params do
              requires :dispute_ids, type: Array[Integer]
            end
            patch 'take_disputes' do
              std_api_v2 do
                authorize!(:update, Dispute)

                dispute_ids = permitted_params['dispute_ids']
                Dispute.take_tickets(dispute_ids, user: current_user)

                { username: current_user.display_name, dispute_ids: dispute_ids }
              end
            end

            params do
              requires :field_data, type: Hash
            end
            patch 'entries/field_data' do
              std_api_v2 do
                authorize!(:update, Dispute)
                DisputeEntry.update_from_field_data(permitted_params['field_data'])
                DisputeEntry.send_status_updates(permitted_params['field_data'])
                true
              end
            end

            params do
              requires :relating_dispute_ids, type: Array[Integer]
            end
            patch ':dispute_id/relating_disputes' do
              std_api_v2 do
                byebug
                authorize!(:update, Dispute)
                relating_dispute_ids = permitted_params['relating_dispute_ids']
                Dispute.where(id: relating_dispute_ids).update_all(related_id: params['dispute_id'],
                                                                   related_at: DateTime.now)
                true
              end
            end

            params do
              requires :related_dispute_id, type: Integer
            end
            post ':dispute_id/related_disputes' do
              std_api_v2 do
                authorize!(:update, Dispute)
                dispute = Dispute.find(params['dispute_id'])
                authorize!(:update, dispute)
                dispute.update!(related_id: permitted_params['related_dispute_id'],
                                related_at: DateTime.now)
                true
              end
            end

            params do
              requires :duplicate_dispute_id, type: Integer
            end
            post ':dispute_id/duplicate_disputes' do
              std_api_v2 do
                authorize!(:update, Dispute)
                dispute = Dispute.find(params['dispute_id'])
                authorize!(:update, dispute)
                dispute.update!(related_id: permitted_params['duplicate_dispute_id'],
                                related_at: DateTime.now,
                                status: Dispute::CLOSED,
                                resolution: Dispute::DUPLICATE)
                true
              end
            end
          end
        end
      end
    end
  end
end
