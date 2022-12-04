module API
  module V1
    module Escalations
      module Webrep
        class Disputes < Grape::API
          include API::V1::Defaults
          include API::BugzillaRestSession

          resource "escalations/webrep/disputes" do
            before do
              PaperTrail.request.whodunnit = current_user.id if current_user.present?
            end
            desc 'get all disputes'
            get "" do
              authorize!(:index, Dispute)
              search_params = {search_type: params[:search_type] || '', search_name: params[:search_name] || ''}
              WebRepDatatable.new(ActionController::Parameters.new(params).permit!, search_params, user: current_user).as_json
            end

            desc 'project new score'
            params do
              requires :url, type: String
              requires :add, type: Array(String)
              requires :remove, type: Array(String)
            end

            post "project_new_score" do
              new_score = Wbrs::ManualWlbl.project_new_score(permitted_params[:url], permitted_params[:add], permitted_params[:remove])
              data = {status: "success", score: new_score}
              data.to_json
            end

            desc 'create a dispute'
            params do
              requires :ips_urls, type: String, desc: 'List of URLs to create entries'
              requires :assignee, type: String, desc: 'Description of new complaint'
              requires :priority, type: String, desc: 'Customer related to new complaint'
              requires :ticket_type, type: String, desc: 'Array of tags to be associated with the new complaint'
            end

            post "" do
              std_api_v2 do
                user_validation = User.where(cvs_username: permitted_params['assignee'])
                separated_entries = permitted_params[:ips_urls].split("\s")
                non_duplicated_entries = []
                duplicates = []

                separated_entries.each do |entry|
                  if DisputeEntry.check_for_duplicates(entry)
                    duplicates << entry
                  else
                    non_duplicated_entries << entry
                  end
                end
                if non_duplicated_entries.any?
                  if user_validation.present?
                    begin
                      dispute = Dispute.create_action(bugzilla_rest_session,
                                                      non_duplicated_entries,
                                                      permitted_params[:assignee],
                                                      permitted_params[:priority],
                                                      permitted_params[:ticket_type])
                    rescue Exception => ex
                      Dispute.log_exception(ex)
                      raise ("Could not create the Dispute because of this error: #{ex.message}")
                    end
                    render json: {status: 'Success', case_id: dispute.id, errors: duplicates}


                  else
                    raise ("Invalid assignee or assignee does not exist. Please try again.")
                  end
                else
                  raise ("Unable to create the following duplicate dispute entries: #{duplicates.join(", ")}")
                end
              end
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
              optional :submission_type, type: String, desc: "Submission type"
            end
            put ":id" do
              resolved_at = Time.now
              dispute = Dispute.find(params[:id])

              dispute.submission_type = permitted_params[:submission_type]
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

              dispute = Dispute.find(params[:dispute_id])

              entry = DisputeEntry.create_dispute_entry(dispute, params[:uri])

              json_packet << entry

              {:status => "success", :data => json_packet}.to_json
            end

            desc "Change assignee of a group of dispute IDs"
            params do
              requires :dispute_ids, type: Array[Integer], desc: "analyst-console database id"
              requires :new_assignee, type: Integer, desc: "User ID of new assignee"
            end
            post "change_assignee" do
              authorize!(:update, Dispute)
              disputes = Dispute.assign(params[:new_assignee], params[:dispute_ids])
              {:status => "success", :data => disputes}.to_json
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
              optional :thrt_cat_ids, type: Array[Integer], desc: "threat categories"
              requires :note, type: String, desc: "note"
            end
            post "uri_wlbl" do
              authorize!(:update, Wbrs::ManualWlbl)
              Wbrs::ManualWlbl.adjust_urls_from_params(permitted_params, username: current_user.cvs_username)
              true
            end




            desc "Bulk adjust WL/BLs and BL threat categories"
            params do
              requires :adjustment_type, type: String, desc: "Add, remove, or replace"
              optional :dispute_entries, type: Array[Integer], desc: "analyst-console database id"
              optional :urls, type: Array[String], desc: "URLs to modify, if Dispute Entry ID is not known"
              requires :lists, type: Array[String], desc: "type of WL/BL"
              optional :thrt_cat_ids, type: Array[Integer], desc: "threat categories"
              requires :note, type: String, desc: "note"
            end
            post "bulk_wlbl_threatcat_adjust" do
              authorize!(:update, Wbrs::ManualWlbl)

              ip_uris = []
              if params[:dispute_entries].present?
                params[:dispute_entries].each do |dispute_entry_id|
                  dispute_entry = DisputeEntry.find(dispute_entry_id)
                  if dispute_entry.entry_type == "IP"
                    ip_uris << dispute_entry.ip_address
                  else
                    ip_uris << dispute_entry.uri
                  end
                end
              else
                ip_uris = params[:urls]
              end

              case params[:adjustment_type]
              when "add"
                if params[:dispute_entries].present?
                  parsed_ip_uris = ip_uris.map{|ip_uri| DisputeEntry.domain_of_with_path(ip_uri).strip}
                  unique_ip_uris = parsed_ip_uris.uniq
                else
                  unique_ip_uris = ip_uris
                end

                wlbl_params =
                    {
                        urls: unique_ip_uris,
                        trgt_list: params['lists'],
                        note: params['note'],
                        usr: current_user.cvs_username,
                        thrt_cat_ids: permitted_params['thrt_cat_ids']
                    }
                Wbrs::ManualWlbl.bulk_new_wlbl_from_params(wlbl_params)
              when "remove"
                Wbrs::ManualWlbl.destroy_from_params(ip_uris, params['lists'], username: current_user.cvs_username)
              when "replace"
                replace_params_formatted =
                    {
                        dispute_entry_ids: params[:dispute_entries],
                        trgt_list: params[:lists],
                        thrt_cats: params[:thrt_cat_ids],
                        note: params[:note]
                    }
                Wbrs::ManualWlbl.adjust_entries_from_params(replace_params_formatted, username: current_user.cvs_username)
              else
                "No valid adjustment type"
              end

              if params[:dispute_entries].present?
                params[:dispute_entries].each do |dispute_entry|
                  dispute = DisputeEntry.where({:id => dispute_entry}).first.dispute
                  DisputeComment.create(:dispute_id => dispute.id, :user_id => current_user.id, :comment => params[:note])
                end
              end

              true
            end










            # TODO: unused?
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

            # TODO: unused?
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
              std_api_v2 do
                params["classifications"][0].slice! "No active classifications,"
                RepApi::Blacklist.adjust_from_params(permitted_params, username: current_user.cvs_username)
                true
              end
            end

            desc "Maintain current classifications for RepTool BL entries"
            params do
              requires :data, type: Array
            end
            post "maintain_reptool_bl" do
              std_api_v2 do

                permitted_params['data'].each do |entry|
                  if entry['action'] != "expired"
                    entry["classifications"][0].slice! "No active classifications,"
                  end
                  RepApi::Blacklist.adjust_from_params(entry, username: current_user.cvs_username)
                end
                true
              end
            end

            desc "Drop a Reptool Bl entry"
            params do
              requires :action, type: String, desc: "activate or expire"
              requires :entries, type: Array[String], desc: "urls"
            end
            post "drop_reptool_bl" do
              std_api_v2 do
                RepApi::Blacklist.adjust_from_params(permitted_params, username: current_user.cvs_username)
                true
              end
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

                raise 'This ticket is already assigned.' unless dispute.user_id.nil? || User.vrtincoming&.id == dispute.user_id

                Dispute.assign(current_user, permitted_params['dispute_id'])

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
                  if entry.length == 3 && entry.last['field'] == 'resolution_comment' && !entry.last['new'].empty?
                    comment = entry.last["new"]
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

              if information[params[:entry].gsub('http://', '').gsub('https://', '')] == "NOT_FOUND"
                return {:entry => params[:entry], :classification => "not found", :expiration => "", :status => "", :comment => ""}.to_json
                # TODO Make expiration human readable - Just the date
              else
                expiration = ""
                begin
                  expiration = Time.parse(information[params[:entry].gsub('http://', '').gsub('https://', '')]["expiration"]).to_s
                rescue
                  expiration = information[params[:entry].gsub('http://', '').gsub('https://', '')]["expiration"]
                end
                return {:entry => params[:entry], :classification => information[params[:entry].gsub('http://', '').gsub('https://', '')]["classifications"], :expiration => expiration, :status => information[params[:entry].gsub('http://', '').gsub('https://', '')]["status"], :comment => information[params[:entry].gsub('http://', '').gsub('https://', '')]["metadata"]["VRT"]["comment"]}.to_json
              end

            end

            params do
              requires :ip_uris, type: Array[String]
            end

            post 'bulk_reptool_get_info_for_form' do
              std_api_v2 do
                api_response = JSON.parse(RepApi::Blacklist.where({entries: permitted_params[:ip_uris] }, true))
                return_data = []

                api_response.each do |key, value|
                  next if value == true || value == false
                  if value[value.keys.first]["result"].downcase == 'not_found' || value[value.keys.first]["result"].downcase == 'failed'
                    return_data.push(:entry => value.keys.first, :classification => "No active classifications", :expiration => "", :status => "INACTIVE", :comment => "")
                    # TODO Make expiration human readable - Just the date
                  else

                    expiration = ""
                    begin
                      expiration = Date.parse(value[value.keys.first]["data"]["expiration"]).to_s
                    rescue
                      expiration = value[value.keys.first]["data"]["expiration"]
                    end

                    comment = ""

                    begin
                      comment = value[value.keys.first]["data"]["sources"].fetch("VRT", {}).fetch("comment", "")
                    rescue
                      comment = ""
                    end

                    return_data.push(:entry => value.keys.first, :classification => value[value.keys.first]["data"]["classifications"], :expiration => expiration, :status => value[value.keys.first]["data"]["status"].upcase, :comment => comment).to_json

                  end
                end
                return_data.to_json
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
              note_entries = []
              notes = ""
              information.each do |entry|
                if entry.url == params[:entry]
                  if entry.state == "active"
                    list_types << entry.list_type
                  end
                end
              end

              note_entries = note_entries.uniq

              return {:status => "success", :data => list_types, :notes => note_entries.first}.to_json

            end

            params do
              requires :uri, type: String
            end

            get 'rule_api_info' do
              params[:uri] = params[:uri].strip

              information = Wbrs::ManualWlbl.where({:url => params[:uri]})

              if information.blank?
                return {:status => 'success', :data => ""}.to_json
              end

              data = []
              information.each do |entry|
                if entry.url == params[:uri]
                  if entry.state == "active"
                    entry.threat_cats = DisputeEntry.threat_cats_from_ids(entry.threat_cats)
                    data << entry
                  end
                end
              end

              note_entries = []

              return {:status => "success", :data => data, :notes => note_entries.first}.to_json

            end









            params do
              requires :entries, type: Array[String]
            end

            post 'bulk_rule_ui_wlbl_get_info_for_form' do
              std_api_v2 do

                params[:entries] = params[:entries].map {|entry| DisputeEntry.domain_of_with_path(entry.strip)}

                data = []
                list_types = {}
                note_entries = []

                params[:entries].each do |entry|
                  list_types[entry] = []
                  api_responses = Wbrs::ManualWlbl.where({:url => entry})

                  api_responses.each do |response|
                    if DisputeEntry.domain_of_with_path(response.url) == entry
                      if response.state == "active"
                        list_types[entry] << response.list_type
                      end
                    end
                  end

                  if ComplaintEntry.is_ip?(entry)
                    params['ip'] = entry
                    wbrs_api_response = Sbrs::ManualSbrs.call_wbrs(params)
                  else
                    params['url'] = entry
                    wbrs_api_response = Sbrs::ManualSbrs.call_wbrs(params, type: 'wbrs')
                  end

                  if wbrs_api_response != nil && wbrs_api_response['wbrs'].present? && wbrs_api_response['wbrs']['score'] != 'noscore'
                    wbrs_score = wbrs_api_response['wbrs']['score']
                  else
                    wbrs_score = nil
                  end

                  if api_responses.blank?
                    data.push({:status => 'error', :ip_uri => entry, :list_types => nil})
                  else
                    data.push({ ip_uri: entry,
                                status: 'success',
                                list_types: list_types[entry],
                                wbrs_score: wbrs_score,
                                notes: note_entries.first })
                  end
                end

                data.to_json
              end
            end

            params do
              requires :ip_uris, type: Array[String]
              requires :list_types, type: Array[String]
              requires :note, type: String
              optional :thrt_cat_ids, type: Array[Integer], desc: "threat categories"
            end

            post 'bulk_rule_ui_wlbl_add' do
              std_api_v2 do
                authorize!(:update, Wbrs::ManualWlbl)
                parsed_ip_uris = permitted_params['ip_uris'].map{|ip_uri| DisputeEntry.domain_of_with_path(ip_uri).strip}
                unique_ip_uris = parsed_ip_uris.uniq

                wlbl_params =
                    {
                        urls: unique_ip_uris,
                        trgt_list: permitted_params['list_types'],
                        note: permitted_params['note'],
                        usr: current_user.cvs_username,
                        thrt_cat_ids: permitted_params['thrt_cat_ids']
                    }

                Wbrs::ManualWlbl.bulk_new_wlbl_from_params(wlbl_params)
              end
            end

            params do
              requires :ip_uris, type: Array[String]
              requires :list_types, type: Array[String]
            end

            post 'bulk_rule_ui_wlbl_remove' do
              std_api_v2 do
                ip_uris = permitted_params[:ip_uris].map {|ip_uri| ip_uri.strip}
                list_types = permitted_params[:list_types]

                Wbrs::ManualWlbl.destroy_from_params(ip_uris, list_types, username: current_user.cvs_username)
              end

            end

            params do
              optional :id, type: Integer
              optional :entry, type: String
            end

            get 'wlbl_history' do
              note_entries = []
              entry = ''
              if params[:id].present?
                entry = DisputeEntry.find_by_id(params[:id]).hostlookup
              else
                entry = params[:entry]
              end

              api_response = Wbrs::ManualWlbl.where({:url => entry})

              api_response.each do |response|
                begin
                  note_entries = note_entries + Wbrs::ManualWlbl.gather_history_entries(response, entry)
                rescue
                  note_entries = note_entries + Wbrs::ManualWlbl.add_to_history_modal(response,'')
                  next
                end
              end

              note_entries = note_entries.sort_by{|vn| vn[:sort_date]}.reverse

              return {:status => "success", :data => note_entries}.to_json
            end

            desc 'Autopopulate fields on Advanced Search'
            get 'autopopulate_advanced_search' do
              case_owners = User.where.not(cvs_username: nil).order(cvs_username: :asc).uniq
              statuses = [Dispute::NEW, Dispute::STATUS_RESEARCHING,Dispute::STATUS_ESCALATED,Dispute::STATUS_CUSTOMER_PENDING, Dispute::ASSIGNED,
                          Dispute::STATUS_ON_HOLD,Dispute::STATUS_RESOLVED,Dispute::STATUS_REOPENED].map {|item| {id: item, public_name: item }}
              submitter_types = ['Customer', 'Non-Customer']
              contacts = Customer.all.order(name: :asc)
              companies = Company.all.order(name: :asc)
              resolutions = Dispute::RESOLUTIONS.map {|item| {id: item, public_name: item }}
              priorities = Dispute::PRIORITIES.map {|item| {id: item, public_name: item }}
              sources = Dispute::SOURCES
              platforms = Platform.all.order(public_name: :asc).map {|m| {id: m.public_name, public_name: m.public_name}}
              render json: {case_owners: case_owners, statuses: statuses, submitter_types: submitter_types,
                            contacts: contacts, companies: companies, resolutions: resolutions,
                            platforms: platforms, priorities: priorities, sources: sources}
            end

            desc 'Auto-populate fields on New Dispute'
            get 'populate_new_dispute_fields' do
              assignees = User.joins(roles: :org_subset).where(org_subsets: { name: 'webrep' }).distinct.order(:cvs_username)

              render json: {assignees: assignees}
            end

            ## for bulk lookup

            desc 'super simple endpoint for bulk lookup to consume'
            params do
              requires :uri, type: String
            end

            get 'wbrs_info' do
              data = {}
              data[:score] = nil
              data[:rulehits] = []

              url_to_test = permitted_params[:uri]

              begin
                results = Sbrs::ManualSbrs.call_wbrs({'url' => url_to_test}, type: 'wbrs')
                data[:score] = results["wbrs"]["score"]
                data[:rulehits] = Sbrs::ManualSbrs.get_rule_names_from_rulehits(results)
                render json: {:status => "success", :data => data}
              rescue
                render json: {:status => "error", :data => data}
              end

            end

            desc 'super simple endpoint to quick look up bulk submit'
            params do
            end

            post 'quick_bulk_update' do
              data = params[:update_data]

              errors = data.keys.reduce([])  do |memo, url|
                memo << url if DisputeEntry.check_for_duplicates(url)
                memo
              end
              
              if errors.any?
                return { status: 'error', message: "Unable to create the following duplicate dispute entries: #{errors.join(', ')}" }.to_json
              end
  
              begin
                response = Dispute.process_quick_bulk_entries(data, current_user)
                { status: 'success', data: response }.to_json
              rescue
                { status: 'error' }.to_json
              end
            end

            desc 'Get URL + IP data from SDS V3'
            post 'update_multi_ip' do

              uri = params[:uri]
              provided_ips = params[:ip_addresses]
              ips = []
              dispute_entry_id = params[:dispute_entry_id]

              dispute_entry = nil

              # Make sure the ips are legit
              provided_ips.each do |ip|
                if DisputeEntry.is_ip?(ip)
                  ips << ip
                end
              end

              if dispute_entry_id.present?
                dispute_entry = DisputeEntry.where(:id => dispute_entry_id).first
              end

              results = DisputeEntry.process_multi_ip_info(uri, ips, dispute_entry)
              render json: {:status => "success", :rulehits => results[:rulehits], :score => results[:score], :proxy_uri => results[:proxy_uri], :threat_cats => results[:threat_cats]}
            end


            params do
              requires :uri, type: String
            end
            desc 'Grab threat categories from SDSv3 API'
            post 'threat_categories' do
              response = SbApi.remote_call_sds_v3(permitted_params[:uri],'wbrs')
              response
            end

            params do
              requires :uri, type: String
            end
            desc 'Grab threat levels from SDSv2 API'
            post 'threat_levels' do
              response = SbApi.remote_call_sds(permitted_params[:uri],'wbrs')
              response

            end

            desc 'valid url?'

            params do
              requires :uri, type: Array[String]
            end
            #this needs to start with 'http' or 'https'
            get 'is_valid_url' do
              urls = permitted_params[:uri]
              result = {}
              urls.each do |url|
                if url.start_with?( 'https://', 'http://')
                  result[url] = DisputeEntry.valid_url?(url)
                else
                  result[url] = DisputeEntry.valid_url?('http://' + url)
                end
              end
              {:status => "success", :data => result, :checked_url => urls}
            end

            desc 'valid ip?'

            params do
              requires :ip_address, type: Array[String]
            end
            #this needs to start with 'http' or 'https'
            get 'is_valid_ip' do
              ips = permitted_params[:ip_address]
              result = {}
              ips.each do |ip|
                result[ip] = DisputeEntry.is_ip?(ip)
              end
              {:status => "success", :data => result, :checked_ips => ips}
            end

            desc 'convert ticket from dispute to complaint'

            params do
              requires :dispute_id, type: Integer
              requires :suggested_categories
              requires :summary, type: String
            end

            post 'convert_ticket' do
              Dispute.convert_to_complaint(permitted_params, current_user)
            end

            params do
              requires :uri, type: Array[String]
            end

            post 'current_content_categories' do
              urls = permitted_params[:uri]
              data = {}
              urls.each_with_index do |url, i|
                data[i] = {'url': url, 'categories': ComplaintEntry.current_category_data_for_uri(url)}
              end
              
              {:status => "success", :data => data}
            end

            params do
              requires :id, type: Integer
            end

            post 'recover_dispute' do
              dispute_to_recover = Dispute.find(params[:id])
              results = dispute_to_recover.rebuild_from_packet
              if results[:errors].present?
                return {:status => "error", :errors => results[:errors], :messages => results[:messages]}
              else
                return {:status => "success", :messages => results[:messages]}
              end
            end
          end
        end
      end
    end
  end
end
