class Escalations::Webrep::DisputesController < ApplicationController

  before_action :require_login

  def index
    @disputes = Dispute.robust_search(params.fetch(:dispute, {})['search_type'],
                                      search_name: params.fetch(:dispute, {})['search_name'],
                                      params: index_params,
                                      user: current_user)
  end

  def show
    @dispute = Dispute.find(params[:id])
    @versioned_items = @dispute.compose_versioned_items

    @entries = @dispute.dispute_entries
    @entries.each { |entry| entry.blacklist(reload: true) }
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
                                                  date_to: params['report']['date_to'])
  end

  def export_per_resolution_report
    @report = DisputeReport::ResolutionReport.new(date_from: params['date_from'],
                                                  date_to: params['date_to'])

    contents = CSV.generate do |csv|
      csv << [ 'Date', 'Resolution', '%', 'Count' ]
      @report.each_per_resolution do |pr_report|
        csv << [ pr_report.date, 'TOTAL', nil, pr_report.total ]
        pr_report.each_resolution do |resolution, percent, count|
          csv << [ pr_report.date, resolution, percent, count ]
        end
      end
    end
    send_data contents
  end

  def export_per_engineer_report
    @report = DisputeReport::ResolutionReport.new(date_from: params['date_from'],
                                                  date_to: params['date_to'])

    contents = CSV.generate do |csv|
      csv << [ 'Date', 'Resolution', '%', 'Count' ]
      @report.each_per_engineer do |pe_report|
        csv << [ pe_report.date, 'TOTAL', nil, pe_report.total ]
        pe_report.each_resolution do |engineer, percent, count|
          csv << [ pe_report.date, engineer, percent, count ]
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

  def index_params
    params.fetch(:dispute, {}).permit(:customer_name, :customer_email, :customer_company_name,
                                      :status, :resolution, :subject,
                                      :value)
  end

  def age_report_params
    params.permit(:date, :resolution, :engineer)
  end
end
