module API
  module V1
    module Escalations
      module Webrep
        class Disputes < Grape::API
          include API::V1::Defaults

          resource "escalations/webrep/disputes" do
            
            desc 'get all disputes'
            params do
            end

            get "" do

              json_packet = []

              # disputes = Dispute.all #.includes(:dispute_entries) #  => (:dispute_rule_hit)
              #disputes = Dispute.robust_search(params.fetch(:dispute, {})['search_type'],
              #                                  search_name: params.fetch(:dispute, {})['search_name'],
              #                                  params: index_params,
              #                                  user: current_user).includes(:dispute_entries => [:dispute_rule_hits])  # [but inside]

              disputes = Dispute.all.includes(:dispute_entries => [:dispute_rule_hits])
              #disputes = Dispute.where("id like '20%'").includes(:dispute_entries => [:dispute_rule_hits])

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
                dispute_packet[:dispute_entries] = []
                unless dispute.dispute_entries.empty?
                  dispute.dispute_entries.each do |entry|
                    unless entry[:ip_address].nil?
                      dispute_packet[:dispute_entries].push(entry[:ip_address])
                    end
                    unless entry[:uri].nil?
                      dispute_packet[:dispute_entries].push(entry[:uri])
                    end
                    unless entry[:hostname].nil?
                      dispute_packet[:dispute_entries].push(entry[:hostname])
                    end
                  end
                end
                dispute_packet[:d_entry_preview] = "<span class='dispute_entry_content_first'>" + dispute_packet[:dispute_entries].first.to_s + "</span><span class='dispute-count'>" + dispute_packet[:dispute_count] + "</span>"
                dispute_packet[:status] = dispute.status
                dispute_packet[:resolution] = dispute.resolution
                dispute_packet[:assigned_to] = ''#dispute.user.email
                dispute_packet[:actions] = "<a href='/escalations/webrep/disputes/#{dispute.id}'>edit</a>"

                dispute_packet[:case_opened_at] = dispute.case_opened_at.strftime('%Y-%m-%d %H:%M:%S')
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

            end

            desc 'delete a dispute'
            params do
            end

            delete "" do

            end

            desc "Add a WL/BL entry"
            params do
              requires :urls, type: Array[String], desc: "urls"
              requires :trgt_list, type: String, desc: "type of WL/BL"
              optional :thrt_cats, type: Array[String], desc: "threat categories"
              requires :note, type: String, desc: "note"
            end
            post "wlbl" do
              wlbl_params = permitted_params.to_h.merge('usr' => current_user.cvs_username)
              Wbrs::ManualWlbl.add_from_params(wlbl_params)
              ''
            end

            desc "Add a Reptool Bl entry"
            params do
              requires :entries, type: Array[String], desc: "urls"
              requires :classifications, type: Array[String], desc: "classifications"
              requires :comment, type: String, desc: "comment"
            end
            post "reptool_bl" do
              reptool_bl_params = permitted_params.to_h.merge('author' => current_user.cvs_username)
              blacklist = Wbrs::Blacklist.new(reptool_bl_params)
              blacklist.save!
              ''
            end

          end
        end
      end
    end
  end
end
