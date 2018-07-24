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

              json_packet = []

              disputes = Dispute.robust_search(permitted_params['search_type'],
                                               search_name: permitted_params['search_name'],
                                               params: permitted_params,
                                               user: current_user).includes(:user, :dispute_entries => [:dispute_rule_hits])  # [but inside]

              disputes.each do |dispute|
                dispute_packet = {}
                dispute_packet[:id] = dispute.id

                dispute_packet[:case_number] = sprintf '%08d', dispute.id
                dispute_packet[:case_link] = "<a href='/escalations/webrep/disputes/#{dispute.id}'>" + dispute_packet[:case_number] + "</a>"
                dispute_packet[:submitter_name] = '' #dispute.customer_name
                dispute_packet[:submitter_org] = dispute.org_domain
                dispute_packet[:submitter_domain] = dispute.org_domain
                dispute_packet[:dispute_domain] = dispute.org_domain
                unless dispute.dispute_entries.empty?
                  unless dispute.dispute_entries.first[:hostname].nil?
                    dispute_packet[:dispute_domain] = dispute.dispute_entries.first[:hostname]
                  end
                end
                dispute_packet[:dispute_count] = dispute.entry_count.to_s

                dispute_packet[:dispute_entry_content] = []
                unless dispute.dispute_entries.empty?
                  dispute.dispute_entries.each do |entry|
                    unless entry[:ip_address].nil?
                      dispute_packet[:dispute_entry_content].push(entry[:ip_address])
                    end
                    unless entry[:uri].nil?
                      dispute_packet[:dispute_entry_content].push(entry[:uri])
                    end
                  end
                end

                dispute_packet[:dispute_entries] = dispute.dispute_entries
                dispute_packet[:d_entry_preview] = "<span class='dispute-submission-type dispute-#{dispute.submission_type}'></span><span class='dispute_entry_content_first'>" + dispute_packet[:dispute_entry_content].first.to_s + "</span><span class='dispute-count'>" + dispute_packet[:dispute_count] + "</span>"
                dispute_packet[:status] = dispute.status
                dispute_packet[:resolution] = dispute.resolution
                dispute_packet[:assigned_to] = ''#dispute.user.email
                if dispute.assignee == 'Unassigned'
                  dispute_packet[:assigned_to] =
                      "<span class='missing-data dispute_username' id='owner_#{dispute.id}'>Unassigned</span><button class='take-ticket-button' title='Assign this ticket to me' onclick='take_dispute(this, #{dispute.id});'></button>"
                end

                if dispute.user_id?
                  dispute_packet[:assigned_to] = User.find(dispute.user_id).cvs_username + " <button class='take-ticket-button' title='Assign this ticket to me'></button>"
                end

                dispute_packet[:actions] = "<a href='/escalations/webrep/disputes/#{dispute.id}'>edit</a>"

                dispute_packet[:case_opened_at] = dispute.case_opened_at&.strftime('%Y-%m-%d %H:%M:%S')
                dispute_packet[:case_age] = dispute.dispute_age
                # dispute_packet[:suggested_disposition] = 'Malicious: Phishing'
                dispute_packet[:suggested_disposition] = dispute.suggested_d
                dispute_packet[:priority] = (( dispute.id % 3 ) + 1).to_s # should be: dispute.priority
                dispute_packet[:source] = dispute.ticket_source.nil? ? "Bugzilla" : dispute.ticket_source
                dispute_packet[:source_id] = dispute.ticket_source_key
                dispute_packet[:source_type] = dispute.ticket_source_type

                dispute_packet[:wbrs_score] = ''
                dispute_packet[:wbrs_rule_hits] = []

                dispute.dispute_entries.each do |d_entry|
                  if dispute_packet[:wbrs_score].empty? and d_entry[:score_type] == "WBRS"
                    dispute_packet[:wbrs_score] = d_entry[:score].to_s unless d_entry[:score].nil?
                  end
                  d_entry.dispute_rule_hits.each do |d_rule|
                    dispute_packet[:wbrs_rule_hits] << d_rule.name
                  end
                end
                dispute_packet[:wbrs_rule_hits] = dispute_packet[:wbrs_rule_hits].join(", ")
                json_packet << dispute_packet
              end
              {:status => "success", :data => json_packet}.to_json

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

            desc "Adjust a WL/BL entry"
            params do
              requires :dispute_entry_ids, type: Array[Integer], desc: "analyst-console database id"
              requires :trgt_list, type: String, desc: "type of WL/BL"
              optional :thrt_cats, type: Array[String], desc: "threat categories"
              requires :note, type: String, desc: "note"
            end
            post "wlbl" do
              authorize!(:update, Wbrs::ManualWlbl)
              Wbrs::ManualWlbl.adjust_from_params(permitted_params, username: current_user.cvs_username)
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

            delete "searches/:search_name" do
              # TODO determine access control policy for named searches
              search = NamedSearch.where(name: params['search_name'], user: current_user)
              search.destroy_all
              true
            end

            patch 'take_dispute/:dispute_id' do
              authorize!(:update, Dispute)
              dispute = Dispute.find(params['dispute_id'])
              authorize!(:update, dispute)

              dispute.take_ticket(user: current_user)

              { username: current_user.display_name, dispute_id: dispute.id }
            end

            params do
              requires :dispute_ids, type: Array[Integer]
            end
            patch 'take_disputes' do
              authorize!(:update, Dispute)

              dispute_ids = permitted_params['dispute_ids']
              Dispute.take_tickets(dispute_ids, user: current_user)

              { username: current_user.display_name, dispute_ids: dispute_ids }
            end
          end
        end
      end
    end
  end
end
