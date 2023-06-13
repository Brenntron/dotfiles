class JiraImportTask < ApplicationRecord
  has_many :import_urls, dependent: :destroy

  validates :issue_key, presence: true, uniqueness: true

  scope :total_count, -> { all.count }
  scope :completed_count, -> { where(status: STATUS_COMPLETE).count }
  scope :failed_count, -> { where(status: STATUS_FAILURE).count }
  scope :pending_count, -> { where(status: STATUS_PENDING).count }
  scope :awaiting_bast_verdict_count, -> { where(status: STATUS_AWAITING_BAST_VERDICT).count }

  STATUS_COMPLETE = "Complete"
  STATUS_FAILURE = "Failure"
  STATUS_PENDING = "Pending"
  STATUS_AWAITING_BAST_VERDICT = "Awaiting Bast Verdict"

  VALID_FILE_TYPE = "text/csv"
  
  EXPORT_FIELD_NAMES = {
    'ISSUE_KEY' => 'Jira Ticket ID',
    'SUBMITTED_URL' => 'Submitted URL',
    'COMPLAINT_ENTRY_ID' => 'Complaint Entry ID',
    'COMPLAINT_ENTRY_STATUS' => 'Complaint Entry Status',
    'COMPLAINT_ENTRY_RESOLUTION' => 'Complaint Entry Resolution',
    'ISSUE_STATUS' => 'Jira Ticket Status',
    'ISSUE_TYPE' => 'Jira Ticket Type',
    'ISSUE_SUMMARY' => 'Summary',
    'ISSUE_SUBMITTER' => 'Submitter',
    'ISSUE_PLATFORM' => 'Platform',
    'STATUS' => 'Ticket Import Status',
    'IMPORTED_AT' => 'Imported At',
    'BAST_COMMENT' => 'BAST comment'
  }

  CACHE_LIFESPAN = 30

  def issue
    @issue ||= JiraRest::Issue.new(issue_key)
  end

  #Read CSV from Jira and send URLs to Bast
  def process_import
    update(imported_at: Time.now)

    custom_fields = JiraRest::Project.new(Rails.configuration.jira.project_key).custom_fields
    issue = JiraRest::Issue.new(issue_key)

    # fetch data from 'URL(s)' ticket field
    begin
      url_field = issue.issue.fields[custom_fields[:urls]].to_s
      url_field.gsub("URLs ONLY - ONE PER LINE - MAXIMUM OF 50", "")
      urls = url_field.split(/[\n,\s]+/).reject(&:blank?)
    rescue
      urls = []
    end

    # fetch data from ticket attachment
    begin
      attachment_to_process = issue.attachments_data.first
    rescue
      if urls.empty?
        update(status: STATUS_FAILURE, result: "Error reading attachment data: #{e.message}")
        return
      end
      attachment_to_process = {}
    end

    if attachment_to_process&.dig(:type) == VALID_FILE_TYPE
      csv_data = attachment_to_process[:content]
      urls += csv_data.map { |m| m[0]&.strip }.reject(&:blank?)
    end

    if urls.empty?
      update(status: STATUS_FAILURE, result: 'No URLs to import')
      return
    end

    urls_to_submit = []
    urls.each do |url|
      begin
        url_parts = Complaint.parse_url(url)
        import_urls.find_or_create_by(submitted_url: url, domain: url_parts[:domain])
        urls_to_submit << url
      rescue PublicSuffix::DomainNotAllowed
        next
      end
    end

    begin
      response = Bast::Base.create_task(urls_to_submit)
      update(status: STATUS_AWAITING_BAST_VERDICT, bast_task: response['task_id'])
    rescue ApiRequester::ApiRequester::ApiRequesterError => e
      update(status: STATUS_FAILURE, result: e.message)
    end
  end
  handle_asynchronously :process_import, :queue => "process_jira_import", :priority => 1

  def create_tickets
    return unless status == STATUS_AWAITING_BAST_VERDICT

    import_urls.where(domain: nil).each do |url|
      url_parts = Complaint.parse_url(url.submitted_url)
      url.update(domain: url_parts[:domain])
    end

    task_status = Bast::Base.get_task_status(bast_task)
    return unless task_status["status"] == "Completed"

    task_results = Bast::Base.get_task_result(bast_task)

    description = "Created from Jira Issue #{issue_key}"
    task_results.each do |k,v|

      ticketable_urls = import_urls.where(domain: k)

      if v["import"] == true
        existing_entry = ComplaintEntry.open.where(domain: k).first
        if existing_entry.present?
          ticketable_urls.each do |ticketable_url|
            ticketable_url.update(bast_verdict: v["import"], complaint_id: existing_entry.complaint_id)
          end
        else
          complaint_options = [
            BugzillaRest::Session.default_session,
            ticketable_urls.first.submitted_url,
            description,
            Customer::JIRA_GENERATED,
            nil,                     # tags
            nil,                     # platform
            Complaint::NEW,          # status
            nil,                     # categories
            nil,                     # user email
            Complaint::JIRA_CHANNEL  # channel
          ]
          response = Complaint.create_action(*complaint_options)
          ticketable_urls.each do |ticketable_url|
            ticketable_url.update(bast_verdict: v["import"], complaint_id: response[:complaint_id])
          end
        end
      else
        ticketable_urls.each do |ticketable_url|
          ticketable_url.update(bast_verdict: v["import"], verdict_reason: v["reason"])
        end
      end
    end

    update(status: STATUS_COMPLETE)
  end
  handle_asynchronously :create_tickets, :queue => "create_complaint_tickets", :priority => 1

  def retry
    return unless status == STATUS_FAILURE
    update(status: STATUS_PENDING, result: nil, imported_at: nil)
    process_import
  end

  def to_hash
    {
        issue_key: issue_key,
        status: status,
        result: result,
        submitter: submitter,
        bast_task: bast_task,
        imported_at: imported_at,
        created_at: created_at,
        updated_at: updated_at,
        total_urls: import_urls.count,
        unimported_urls: unimported_urls.count,
        imported_urls: imported_urls.count
    }
  end

  def unimported_urls
    import_urls.where("bast_verdict = false or bast_verdict is NULL")
  end

  def imported_urls
    import_urls.where(bast_verdict: true)
  end

  def self.question_type_ticket_count
    filters = ['status != Resolved', "issuetype = 'Question / Assistance'"]
    project_key = Rails.configuration.jira.project_key

    stored_count = JSON.parse(Rails.cache.read("question_type_count") || "{}")
    if stored_count.blank? || stored_count['last_queried'] < 15.minutes.ago
      project = JiraRest::Project.new(project_key)
      issues = project.issues(filters)
      count = issues.count
      Rails.cache.write("question_type_count", {'count' => count, 'last_queried' => Time.now}.to_json)
    else
      count = stored_count['count']
    end
    count
  end

  def self.export_xlsx(issue_keys='')
    issue_keys = issue_keys.split(',')

    tasks = issue_keys.empty? ? JiraImportTask.all : JiraImportTask.where(issue_key: issue_keys)
    tasks = tasks.includes(:import_urls)
    workbook = RubyXL::Workbook.new
    worksheet = workbook[0]

    # generate table headers
    EXPORT_FIELD_NAMES.values.each_with_index  do |field_name, col_index|
      worksheet.add_cell(0, col_index, field_name)
      worksheet.sheet_data[0][col_index].change_font_bold(true)
    end

    row_index = 0
    tasks.each do |task|
      task.import_urls.each do |import_url|
        row_index += 1
        EXPORT_FIELD_NAMES.keys.each_with_index do |field_name, col_index|
          cell_data =
            case field_name
            when 'SUBMITTED_URL'
              import_url.submitted_url
            when 'ISSUE_KEY'
              task.issue_key
            when 'STATUS'
              task.status
            when 'ISSUE_SUBMITTER'
              task.submitter
            when 'IMPORTED_AT'
              task.imported_at.utc.iso8601
            when 'ISSUE_STATUS'
              task.issue_status
            when 'ISSUE_PLATFORM'
              task.issue_platform
            when 'ISSUE_SUMMARY'
              task.issue_summary
            when 'ISSUE_TYPE'
              task.issue_type
            when 'COMPLAINT_ENTRY_ID'
              import_url.complaint_entries.first&.id
            when 'COMPLAINT_ENTRY_STATUS'
              import_url.complaint_entries.first&.status
            when 'COMPLAINT_ENTRY_RESOLUTION'
              import_url.complaint_entries.first&.resolution
            when 'BAST_COMMENT'
              import_url.verdict_reason || 'Inactive'
            end
          worksheet.add_cell(row_index, col_index, cell_data)
        end
      end
    end
    workbook
  end

  def issue_status
    issue_data = JSON.parse(Rails.cache.read("#{issue_key}") || "{}")

    if issue_data.blank? || issue_data['last_queried'] < CACHE_LIFESPAN.minutes.ago
      issue_status = issue.issue.status.name
      Rails.cache.write("#{issue_key}", {'status' => issue_status, 'last_queried' => Time.now}.to_json)
    else
      issue_status = issue_data['status']
    end
    issue_status
  end
end
