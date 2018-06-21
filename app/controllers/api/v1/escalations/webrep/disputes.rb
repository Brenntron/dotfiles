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

              # disputes = Dispute.all.includes(:dispute_entries => [:dispute_rule_hits])
              disputes = Dispute.where("id like '20%'").includes(:dispute_entries => [:dispute_rule_hits])

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
                # dispute_packet[:dispute_count] = dispute.dispute_entries.count.to_s
                dispute_packet[:dispute_count] = dispute.entry_count.to_s
                dispute_packet[:status] = dispute.status.upcase
                dispute_packet[:assigned_to] = dispute.assignee
                dispute_packet[:actions] = "<a href='/escalations/webrep/disputes/#{dispute.id}'>edit</a>"

                dispute_packet[:case_opened_at] = dispute.case_opened_at.strftime('%Y-%m-%d %H:%M:%S')
                dispute_packet[:case_age] = dispute.dispute_age
                # dispute_packet[:suggested_disposition] = 'Malicious: Phishing'
                dispute_packet[:suggested_disposition] = dispute.suggested_d
                #dispute_packet[:priority] = "P" + (( dispute.id % 3 ) + 1).to_s # should be: dispute.priority
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

          end

        end
      end
    end
  end
end

=begin
            get "my" do

              json_packet = []

              disputes = Dispute.where("id like '20%18'") # random subset, for now

              disputes.each do |dispute|
                dispute_packet = {}
                dispute_packet[:id] = dispute.id

                dispute_packet[:customer_name] = '' #dispute.customer_name
                dispute_packet[:customer_company_name] = '' #dispute.org_domain # should be: dispute.customer_company_name
                dispute_packet[:status] = dispute.status.upcase
                dispute_packet[:assigned_to] = dispute.assignee
                dispute_packet[:actions] = "<a href='/escalations/webrep/disputes/#{dispute.id}'>edit</a>"
                dispute_packet[:case_number] = "<a href='/escalations/webrep/disputes/#{dispute.id}'>" + ( sprintf '%08d', dispute.id ).to_s + "</a>"

                dispute_packet[:case_opened_at] = dispute.case_opened_at.strftime('%Y-%m-%d %H:%M:%S')
                dispute_packet[:case_age] = dispute.dispute_age
                # dispute_packet[:suggested_disposition] = 'Malicious: Phishing'
                dispute_packet[:suggested_disposition] = dispute.suggested_d
                dispute_packet[:priority] = "P" + (( dispute.id % 3 ) + 1).to_s # should be: dispute.priority
                dispute_packet[:source] = dispute.ticket_source
                dispute_packet[:source_id] = dispute.ticket_source_key

                json_packet << dispute_packet
              end
              {:status => "success", :data => json_packet}.to_json

            end
=end
