class Escalations::Webrep::DisputesController < ApplicationController
  load_and_authorize_resource class: 'Dispute'

  before_action :require_login

  def index
    respond_to do |format|
      format.html
      format.csv do
        index_params = JSON.parse(params['data_json'])
        search_type = index_params['search_type']
        search_name = 'advanced' == search_type ? nil : index_params['search_name']
        @disputes = Dispute.robust_search(search_type,
                                          search_name: search_name,
                                          params: index_params,
                                          user: current_user)
        contents = CSV.generate do |csv|
          csv << [ 'Priority', 'Case ID', 'Status', 'Dispute', 'Count', 'Owner', 'Time Submitted', 'Age' ]
          @disputes.each do |dispute|
            csv << [
                'P3',
                dispute.case_number,
                dispute.status,
                dispute.org_domain,
                dispute.dispute_entries.count,
                dispute.user.cvs_username,
                dispute.case_opened_at,
                ApplicationRecord.humanize_secs(Time.now - dispute.case_opened_at)
            ]
          end
        end
        send_data contents
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
    # This is temporary till we get the searched hooked up
    @entries = DisputeEntry.all.limit(5)
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
      csv << [ 'Date', 'Resolution', 'Engineer', 'Opened', 'Resolved', 'Time to Resolution' ]
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
end
