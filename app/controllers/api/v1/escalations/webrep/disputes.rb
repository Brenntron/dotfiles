module API
  module V1
    module Escalations
      module Webrep
        class Disputes < Grape::API
          include API::V1::Defaults

          resource "escalations/webrep/disputes" do
            before do
              PaperTrail.request.whodunnit = current_user.id if current_user.present?
            end
            desc 'get all disputes'
            params do
              optional :search_type, type: String
              optional :search_name, type: String
              optional :value, type: String
              optional :case_id, type: String
              optional :org_domain, type: String
              optional :case_owner_username, type: String
              optional :status, type: String
              optional :priority, type: String
              optional :resolution, type: String
              optional :submission_type, type: Array[String]
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
              json_packet = Dispute.to_data_packet(disputes, user: current_user)

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
              optional :priority, type: String, desc: "Priority of P1 through P5"
              optional :customer_name, type: String, desc: "Name of the customer associated with this dispute. Note that changing this changes this customer's name on all their disputes."
              optional :customer_email, type: String, desc: "Email of the customer associated with this dispute"
              optional :status, type: String, desc: "Status of the dispute"
              optional :related_id, type: Integer, desc: "ID of a dispute to relate to this one"
              optional :comment, type: String, desc: "Comment, available regardless of whether resolving"
              optional :resolution, type: String, desc: "Resolution; write this if status is Resolved"
            end
            put ":id" do
              resolved_at = Time.now
              dispute = Dispute.find(params[:id])

              dispute.priority = permitted_params[:priority]
              dispute.customer.name = permitted_params[:customer_name]
              dispute.customer.email = permitted_params[:customer_email]

              if permitted_params[:status]
                dispute.status = permitted_params[:status]
                if permitted_params[:status] == Dispute::STATUS_ASSIGNED
                  dispute.case_accepted_at = Time.now
                end
              end

              if permitted_params[:resolution]
                dispute.resolution = permitted_params[:resolution]
                dispute.case_resolved_at = resolved_at
                dispute.case_closed_at = resolved_at
              end

              dispute.save
              dispute.customer.save

              if permitted_params[:related_id]
                related_dispute = Dispute.find(permitted_params[:related_id])
                related_dispute.related_id = params[:id]
                related_dispute.related_at = Time.now
                related_dispute.save
              end


              if permitted_params[:comment]
                dispute_comment = DisputeComment.new
                dispute_comment.dispute = dispute
                dispute_comment.comment = permitted_params[:comment]
                dispute_comment.save
              end

              dispute.to_json
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

              user = Dispute.find(params[:dispute_id]).user_id

              entry = DisputeEntry.new(:dispute_id => params[:dispute_id], :user_id => user, status: Dispute::NEW, case_opened_at: Time.now)

              is_ip_address = !!(params[:uri]  =~ Resolv::IPv4::Regex)

              if is_ip_address
                entry.ip_address = params[:uri]
                entry.save
                Preloader::Base.fetch_all_api_data(entry.ip_address, entry.id)
              else
                entry.uri = params[:uri]
                entry.save
                Preloader::Base.fetch_all_api_data(entry.uri, entry.id)
              end

              json_packet << entry

              {:status => "success", :data => json_packet}.to_json if entry.save
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
                if d.status == Dispute::STATUS_NEW || d.status == Dispute::STATUS_REOPENED
                  accepted_at = Time.now
                  d.update(status: Dispute::STATUS_ASSIGNED, case_accepted_at: accepted_at)
                  d.dispute_entries.each do |entry|
                    if entry.status == DisputeEntry::NEW || entry.status == DisputeEntry::STATUS_REOPENED
                      entry.update(status: DisputeEntry::ASSIGNED, case_accepted_at: accepted_at)
                    end
                  end
                end
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
                if d.status == Dispute::ASSIGNED
                  d.update(status: Dispute::NEW, case_accepted_at: nil)
                  d.dispute_entries.each do |entry|
                    if entry.status == DisputeEntry::ASSIGNED
                      entry.update(status: DisputeEntry::NEW, case_accepted_at: nil)
                    end
                  end

                  message = Bridge::DisputeEntryUpdateStatusEvent.new
                  message.post_entries(d.dispute_entries)
                end

                raise "This record changed while you were editing. To continue this operation anyway, reload the page and make your assignment again." unless d.user_id == vrt.id
                json_packet << d
              end
              {:status => "success", :data => json_packet}.to_json
            end

            desc "Adjust a WL/BL entry via uris"
            params do
              requires :urls, type: Array[String], desc: "uris to wl/bl"
              requires :trgt_list, type: Array[String], desc: "type of WL/BL"
              optional :thrt_cats, type: Array[String], desc: "threat categories"
              requires :note, type: String, desc: "note"
            end
            post "uri_wlbl" do
              authorize!(:update, Wbrs::ManualWlbl)
              Wbrs::ManualWlbl.adjust_urls_from_params(permitted_params, username: current_user.cvs_username)
              true
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
              dispute = DisputeEntry.where({:id => params[:dispute_entry_ids].first}).first.dispute
              DisputeComment.create(:dispute_id => dispute.id, :user_id => current_user.id, :comment => params[:note])
              true
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
              optional :dispute_entry_ids, type: Array[Integer], desc: "analyst-console database id"
              optional :entries, type: Array[String], desc: "urls"
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

            params do
              requires :dispute_id, type: Integer
            end
            patch 'take_dispute/:dispute_id' do
              std_api_v2 do
                dispute = Dispute.find(permitted_params['dispute_id'])
                authorize!(:update, dispute)

                dispute.take_ticket(user: current_user)

                { username: current_user.cvs_username, dispute_id: dispute.id }
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

                { username: current_user.cvs_username, dispute_ids: dispute_ids }
              end
            end

            params do
              requires :dispute_id, type: Integer
            end
            patch 'return_dispute/:dispute_id' do
              std_api_v2 do
                dispute = Dispute.find(permitted_params['dispute_id'])
                authorize!(:update, dispute)

                dispute.return_dispute

                message = Bridge::DisputeEntryUpdateStatusEvent.new
                message.post_entries(dispute.dispute_entries)


                { dispute_id: dispute.id }
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

                permitted_params['field_data'].each do |index, entry|
                  if entry.length == 3 && entry.last.field == 'resolution_comment' && !entry.last.new.empty?
                    comment = entry.last.new
                    dispute_entry_id = index
                    Dispute.create_note(current_user, comment, dispute_entry_id)
                  end
                end

                true
              end
            end

            params do
              requires :dispute_id, type: Integer
              requires :comment, type: String
            end
            post 'create_note' do
              std_api_v2 do
                Dispute.create_note(permitted_params['dispute_id'], permitted_params['comment'])
              end
            end

            params do
              requires :dispute_ids, type: Array[String]
              requires :status, type: String
              optional :resolution, type: String
              optional :comment, type: String
            end

            post 'set_disputes_status' do

              authorize!(:update, Dispute)
              dispute_ids = params[:dispute_ids].map{|id| id.to_i}
              status = params[:status]
              resolution = ""
              comment = ""
              if params[:resolution].present?
                resolution = params[:resolution]
              else
                resolution = nil
              end

              if params[:comment].present?
                if status == 'RESOLVED_CLOSED'
                  comment = status + ' : ' + resolution + ' - ' + params[:comment]
                else
                  comment = status + ' - ' + params[:comment]
                end
              end

              disputes = Dispute.where(id: dispute_ids)

              Dispute.process_status_changes(disputes, status, resolution, comment, current_user)
              {:status => "success"}.to_json
            end

            get ':dispute_id/related_disputes' do
              std_api_v2 do
                authorize!(:update, Dispute)
                Dispute.where(related_id: params['dispute_id'])
              end
            end

            params do
              requires :relating_dispute_ids, type: Array[Integer]
            end
            patch ':dispute_id/relating_disputes' do
              std_api_v2 do
                authorize!(:update, Dispute)
                relating_dispute_ids = permitted_params['relating_dispute_ids']
                Dispute.where(id: relating_dispute_ids).update_all(related_id: params['dispute_id'],
                                                                   related_at: DateTime.now)
                true
              end
            end

            params do
              requires :relating_dispute_ids, type: Array[Integer]
              optional :original_dispute_id, type: Integer
            end
            patch 'related_disputes' do
              std_api_v2 do
                authorize!(:update, Dispute)
                relating_dispute_ids = permitted_params['relating_dispute_ids']
                Dispute.where(id: relating_dispute_ids).update_all(related_id: permitted_params['original_dispute_id'],
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
              requires :dispute_id, type: Integer
            end
            get 'dispute_status/:dispute_id' do
              std_api_v2 do
                dispute = Dispute.find(permitted_params['dispute_id'])
                status = dispute.status
                if dispute.status == DisputeEntry::STATUS_RESOLVED
                  comment = dispute.resolution_comment
                elsif dispute.status != DisputeEntry::STATUS_RESOLVED
                  comment = dispute.status_comment
                else
                  comment = nil
                end

                {:status => status, :comment => comment}.to_json
              end
            end

            params do
              requires :dispute_id, type: Integer
            end
            get 'dispute_resolution/:dispute_id' do
              std_api_v2 do
                dispute = Dispute.find(permitted_params['dispute_id'])
                resolution = dispute.resolution

                if dispute.resolution_comment.present?
                  resolution_comment = dispute.resolution_comment
                else
                  resolution_comment = ''
                end

                {:resolution => resolution, :resolution_comment => resolution_comment}.to_json
              end
            end

            params do
              requires :dispute_entry_id, type: Integer
            end
            get 'dispute_entry_status/:dispute_entry_id' do
              std_api_v2 do
                dispute_entry = DisputeEntry.find(permitted_params['dispute_entry_id'])
                status = dispute_entry.status
                {:status => status}.to_json
              end
            end

            params do
              requires :dispute_entry_id, type: Integer
            end
            get 'dispute_entry_resolution/:dispute_entry_id' do
              std_api_v2 do
                dispute_entry = DisputeEntry.find(permitted_params['dispute_entry_id'])

                resolution = dispute_entry.resolution

                if dispute_entry.resolution_comment.present?
                  resolution_comment = dispute_entry.resolution_comment
                else
                  resolution_comment = ''
                end

                {:resolution => resolution}.to_json
              end
            end

            params do
              requires :duplicate_dispute_id, type: Integer
            end
            post ':dispute_id/duplicate_disputes' do
              std_api_v2 do
                authorize!(:update, Dispute)
                dispute = Dispute.find(params['dispute_id'])
                resolved_at = Time.now
                authorize!(:update, dispute)
                dispute.update!(related_id: permitted_params['duplicate_dispute_id'],
                                related_at: DateTime.now,
                                status: Dispute::CLOSED,
                                resolution: Dispute::DUPLICATE,
                                case_closed_at: resolved_at,
                                case_resolved_at: resolved_at)
                true
              end
            end

            params do
              requires :entry, type: String
            end

            get 'reptool_get_info_for_form' do
              params[:entry] = params[:entry].strip
              information = RepApi::Blacklist.where({entries: [ params[:entry] ]}, true)
              information = JSON.parse(information)

              if information[params[:entry]] == "NOT_FOUND"
                return {:classification => "not found", :expiration => "", :status => "", :comment => ""}.to_json
              else
                expiration = ""
                begin
                  expiration = Time.parse(information[params[:entry]]["expiration"]).to_s
                rescue
                  expiration = information[params[:entry]]["expiration"]
                end
                return {:classification => information[params[:entry]]["classifications"].first, :expiration => expiration, :status => information[params[:entry]]["status"], :comment => information[params[:entry]]["metadata"]["VRT"]["comment"]}.to_json
              end

            end

            params do
              requires :entry, type: String
            end

            get 'rule_ui_wlbl_get_info_for_form' do
              params[:entry] = params[:entry].strip
              
              information = Wbrs::ManualWlbl.where({:url => params[:entry]})

              if information.blank?
                return {:status => 'success', :data => ""}.to_json
              end

              list_types = []
              information.each do |entry|
                if entry.url == params[:entry]
                  if entry.state == "active"
                    list_types << entry.list_type
                  end
                end
              end

              return {:status => "success", :data => list_types}.to_json

            end

            desc 'Autopopulate fields on Advanced Search'
            get 'autopopulate_advanced_search' do
              case_owners = User.joins(:disputes).where.not(cvs_username: nil).order(cvs_username: :asc).uniq
              statuses = [Dispute::STATUS_RESEARCHING,Dispute::STATUS_ESCALATED,Dispute::STATUS_CUSTOMER_PENDING,
                          Dispute::STATUS_ON_HOLD,Dispute::STATUS_RESOLVED,Dispute::STATUS_REOPENED]
              submitter_types = ['Customer', 'Non-Customer']
              contacts = Customer.all.order(name: :asc)
              companies = Company.all.order(name: :asc)
              resolutions = [Dispute::STATUS_RESOLVED_FIXED_FP, Dispute::STATUS_RESOLVED_FIXED_FN, Dispute::STATUS_RESOLVED_UNCHANGED,
                             Dispute::STATUS_RESOLVED_INVALID, Dispute::STATUS_RESOLVED_TEST, Dispute::STATUS_RESOLVED_OTHER]

              render json: {case_owners: case_owners, statuses: statuses, submitter_types: submitter_types,
                            contacts: contacts, companies: companies, resolutions: resolutions }
            end

          end
        end
      end
    end
  end
end
