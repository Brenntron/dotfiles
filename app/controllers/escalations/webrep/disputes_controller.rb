class Escalations::Webrep::DisputesController < ApplicationController
  load_and_authorize_resource class: 'Dispute'

  before_action :require_login

  def index
    respond_to do |format|
      format.html
      format.xlsx do
        index_params = JSON.parse(params['data_json'])
        search_type = index_params['search_type']
        search_name = 'advanced' == search_type ? nil : index_params['search_name']
        @disputes = Dispute.robust_search(search_type,
                                          search_name: search_name,
                                          params: index_params,
                                          user: current_user)
        contents = RubyXL::Workbook.new
        @worksheet = contents[0]

        def insert_row_with_data(data, format = nil)
          data_insertion_index = @worksheet.sheet_data.rows.count
          data.each_with_index do |new_data, i|
            @worksheet.add_cell(data_insertion_index, i, new_data)
            case format
              when "bold"
                @worksheet.sheet_data[data_insertion_index][i].change_font_bold(true)
              when "h1"
                @worksheet.sheet_data[data_insertion_index][i].change_font_bold(true)
                @worksheet.sheet_data[data_insertion_index][i].change_font_size(14)
              when "h2"
                @worksheet.sheet_data[data_insertion_index][i].change_font_bold(true)
                @worksheet.sheet_data[data_insertion_index][i].change_font_size(12)
            end
          end
        end

        dispute_headers = ['Priority', 'Case ID', 'Status', 'Entry Count', 'Owner', 'Customer Name', 'Customer Email', 'Customer Company', 'Company URL', 'Time Submitted', 'Age', 'Dispute Entry', 'Dispute Entry Status', 'Suggested Disposition', 'Category', 'WBRS Score', 'WBRS Total Rule Hits', 'SBRS Score', 'SBRS Total Rule Hits', 'Important?', 'Resolution', 'Resolution Comments']
        insert_row_with_data(dispute_headers, "h1")

        @disputes.each do |dispute|
          # insert_row_with_data([dispute.priority, dispute.case_id_str, dispute.status, dispute.org_domain, dispute.dispute_entries.count, dispute.user.cvs_username, dispute.case_opened_at, ApplicationRecord.humanize_secs(Time.now - dispute.case_opened_at)], "h2")
          # insert_row_with_data([ 'Dispute Entry', 'Dispute Entry Status', 'Suggested Disposition', 'Category', 'WBRS Score', 'WBRS Total Rule Hits', 'SBRS Score', 'SBRS Total Rule Hits', 'Important?', 'Resolution', 'Resolution Comments' ], "bold")
          dispute.dispute_entries.each do |dispute_entry|
            insert_row_with_data([ dispute_entry.dispute.priority, dispute_entry.dispute.case_id_str, dispute_entry.dispute.status, dispute_entry.dispute.dispute_entries.count, dispute_entry.dispute.user.cvs_username, dispute_entry.dispute.customer.name, dispute_entry.dispute.customer.email, dispute_entry.dispute.customer.company.name, dispute_entry.dispute.org_domain ,dispute_entry.dispute.case_opened_at.strftime("%FT%T"), ApplicationRecord.humanize_secs(Time.now - dispute_entry.dispute.case_opened_at), dispute_entry.hostlookup, dispute_entry.status, dispute_entry.suggested_disposition, dispute_entry.primary_category, dispute_entry.wbrs_score, dispute_entry.dispute_rule_hits.wbrs_rule_hits.count, dispute_entry.sbrs_score, dispute_entry.dispute_rule_hits.sbrs_rule_hits.count, dispute_entry.is_important, dispute_entry.resolution, dispute_entry.resolution_comment ])
          end

        end

        send_data contents.stream.string, filename: "disputes_search_#{Time.now}.xlsx",
                  disposition: 'attachment'
      end
    end
  end

  def show
    @dispute = Dispute.eager_load([:dispute_comments, :dispute_emails]).eager_load(:dispute_entries => [:dispute_rule_hits, :dispute_entry_preload]).where(:id => params[:id]).first
    @versioned_items = @dispute.compose_versioned_items

    @entries = @dispute.dispute_entries

    @entries.each do |entry|
      if entry.dispute_entry_preload.blank?
        Preloader::Base.fetch_all_api_data(entry.hostlookup, entry.id)
      end
    end

    @dispute.peek(user: current_user)

    #@entries.each do |entry|
      #todo: do lazy load style checking with blacklist here
      #entry.blacklist(reload: true)

    #end
  end

  def update
  end

  def dashboard
  end

  def research
    @entries = DisputeEntry.research_results(research_params)
  end

  def tickets
  end
  
  def advanced_search
    @dispute = Dispute.new
  end

  def named_search
  end

  def standard_search
  end

  def contains_search
  end

  def export
    @dispute = Dispute.find(params[:id])
    contents = CSV.generate do |csv|
      csv << [
          'WBRS',
          'WBRS Rule Hits',
          'WBRS Rules',
          'SBRS',
          'SBRS Rule Hits',
          'SBRS Rules',
          'XBRS History',
          'Crosslisted URLs',
          'VirusTotal Negatives',
          'VirusTotal Total',
          'RepTool Class',
          'Blacklist Status',
          'Blacklist Comment',
          'WL/BL',
          'Umbrella',
          'Referenced On',
          'Last Submitted'
      ]
      @dispute.dispute_entries.each do |entry|
        csv << [
            entry.wbrs_score,
            entry.dispute_rule_hits.wbrs_rule_hits.count,
            "\"#{entry.dispute_rule_hits.wbrs_rule_hits.map {|wbrs_hit| wbrs_hit.name}.join(', ')}\"",
            entry.sbrs_score,
            entry.dispute_rule_hits.sbrs_rule_hits.count,
            "\"#{entry.dispute_rule_hits.sbrs_rule_hits.map {|wbrs_hit| wbrs_hit.name}.join(', ')}\"",
            entry.hostlookup && entry.find_xbrs[1]['data'].count,
            entry.wbrs_xlist.count,
            entry.virustotals_negatives_count,
            entry.virustotals.count,
            entry.classifications.first,
            entry.classifications.first && entry.blacklist.status,
            entry.classifications.first && entry.blacklist.metadata&.fetch('VRT', {})['comment'],
            entry.wbrs_list_type,
            entry.umbrellaresult,
            entry.referenced_tickets.count,
            entry.last_submitted.to_s,
        ]
      end
    end
    send_data contents
  end

  def resolution_report
    @report = DisputeReport::ResolutionReport.new(date_from: params['report']['date_from'],
                                                  date_to: params['report']['date_to'],
                                                  period: params['report']['period'])
  end

  def export_per_resolution_report
    @report = DisputeReport::ResolutionReport.new(date_from: params['date_from'],
                                                  date_to: params['date_to'],
                                                  period: params['period'])

    contents = CSV.generate do |csv|
      csv << [ 'Date From', 'Date To', 'Resolution', '%', 'Count' ]
      @report.each_per_resolution do |pr_report|
        csv << [ pr_report.date_from, pr_report.date_to, 'TOTAL', nil, pr_report.total ]
        pr_report.each_resolution do |resolution, percent, count|
          csv << [ pr_report.date_from, pr_report.date_to, resolution, percent, count ]
        end
      end
    end
    send_data contents
  end

  def export_per_engineer_report
    @report = DisputeReport::ResolutionReport.new(date_from: params['date_from'],
                                                  date_to: params['date_to'],
                                                  period: params['period'])

    contents = CSV.generate do |csv|
      csv << [ 'Date From', 'Date To', 'Resolution', '%', 'Count' ]
      @report.each_per_engineer do |pe_report|
        csv << [ pe_report.date_from, pe_report.date_to, 'TOTAL', nil, pe_report.total ]
        pe_report.each_resolution do |engineer, percent, count|
          csv << [ pe_report.date_from, pe_report.date_to, engineer, percent, count ]
        end
      end
    end
    send_data contents
  end

  def export_per_customer_report
    @report = DisputeReport::ResolutionReport.new(date_from: params['date_from'],
                                                  date_to: params['date_to'],
                                                  period: params['period'])

    contents = CSV.generate do |csv|
      csv << [ 'Date From', 'Date To', 'Resolution', '%', 'Count' ]
      @report.each_per_customer do |pe_report|
        csv << [ pe_report.date_from, pe_report.date_to, 'TOTAL', nil, pe_report.total ]
        pe_report.each_resolution do |customer, percent, count|
          csv << [ pe_report.date_from, pe_report.date_to, customer.name, percent, count ]
        end
      end
    end
    send_data contents
  end

  def resolution_age_report
    @entries = DisputeEntry.from_age_report_params(age_report_params)
  end

  def export_resolution_age_report
    @entries = DisputeEntry.from_age_report_params(age_report_params)

    contents = CSV.generate do |csv|
      csv << [ 'When Resolved', 'Resolution', 'Engineer', 'Opened', 'Resolved', 'Time to Resolution' ]
      @entries.each do |entry|
        csv << [
            entry.case_resolved_at,
            entry.resolution,
            entry.cvs_username,
            entry.case_opened_at,
            entry.case_resolved_at,
            ApplicationRecord.humanize_secs(entry.case_resolved_at - entry.case_opened_at)
        ]
      end
    end
    send_data contents
  end

  private

  def search_params
    params.fetch(:dispute, {}).permit(:search_type, :search_name)
  end

  def index_params
    params.fetch(:dispute, {}).permit(:customer_name, :customer_email, :customer_company_name,
                                      :status, :resolution, :subject,
                                      :value)
  end

  def age_report_params
    params.permit(:date_from, :date_to, :resolution, :engineer, :customer_id)
  end

  def research_params
    params.fetch(:search, {}).permit(:uri, :scope)
  end
end
