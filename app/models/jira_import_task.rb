class JiraImportTask < ApplicationRecord
  has_many :import_urls

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
  
  EXPORT_FIELD_NAMES = [
    'SUBMITTED_URL',
    'DOMAIN',
    'ISSUE_KEY',
    'STATUS',
    'ISSUE_SUBMITTER',
    'BAST_TASK_ID',
    'IMPORTED_AT'
  ]

  #Read CSV from Jira and send URLs to Bast
  def process_import
    update(imported_at: Time.now)

    issue = JiraRest::Issue.new(issue_key)

    begin
      attachments = issue.attachments_data
    rescue => e
      update(status: STATUS_FAILURE, result: "Error reading attachment data: #{e.message}")
      return
    end

    if attachments.empty?
      update(status: STATUS_FAILURE, result: "No CSV attachment found")
      return
    end
    attachment_to_process = attachments.first
    if attachment_to_process[:type] == VALID_FILE_TYPE
      csv_data = attachment_to_process[:content]
      urls = csv_data.map {|m| m[0]&.strip}.reject {|r| r.blank?}
      
      if urls.empty?
        update(status: STATUS_FAILURE, result: "No URLs to import")
        return
      end

      urls.each do |url|
        parsed_url = Complaint.parse_url(url)
        import_urls.find_or_create_by(submitted_url: url, domain: parsed_url[:domain])
      end

      begin
        response = Bast::Base.create_task(urls)
        update(status: STATUS_AWAITING_BAST_VERDICT, bast_task: response["task_id"])
      rescue ApiRequester::ApiRequester::ApiRequesterError => e
        update(status: STATUS_FAILURE, result: e.message)
      end

    else
      update(status: STATUS_FAILURE, result: "Invalid file type: #{attachment_to_process[:type]}")
    end
  end
  handle_asynchronously :process_import, :queue => "process_jira_import", :priority => 1

  def create_tickets
    return unless status == STATUS_AWAITING_BAST_VERDICT

    task_status = Bast::Base.get_task_status(bast_task)
    return unless task_status["status"] == "Completed"

    task_results = Bast::Base.get_task_result(bast_task)

    task_results.each do |k,v|
      ticketable_urls = []

      ticketable_urls << import_urls.where(submitted_url: k).first
      if v["urls"].present?
        v["urls"].each do |url|
          ticketable_urls << import_urls.where(submitted_url: url).first
        end
      end

      ticketable_urls = ticketable_urls.reject {|r| r.nil?}

      description = "Created from Jira Issue #{issue_key}"

      ticketable_urls.each do |ticketable_url|
        ticketable_url.update(bast_verdict: v["import"])
        if v["import"] == true
          response = Complaint.create_action(BugzillaRest::Session.default_session, ticketable_url.submitted_url, description, nil, nil, nil)
          ticketable_url.update(complaint_id: response[:complaint_id])
        else
          ticketable_url.update(verdict_reason: v["reason"])
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

  def self.export_xlsx(issue_keys='')
    issue_keys = issue_keys.split(',')

    tasks = issue_keys.empty? ? JiraImportTask.all : JiraImportTask.where(issue_key: issue_keys)
    tasks = tasks.includes(:import_urls)
    workbook = RubyXL::Workbook.new
    worksheet = workbook[0]

    # generate table headers
    EXPORT_FIELD_NAMES.each_with_index  do |field_name, col_index|
      worksheet.add_cell(0, col_index, field_name)
      worksheet.sheet_data[0][col_index].change_font_bold(true)
    end

    row_index = 0
    tasks.each do |task|
      task.import_urls.each do |import_url|
        row_index += 1
        EXPORT_FIELD_NAMES.each_with_index do |field_name, col_index|
          cell_data =
            case field_name
            when 'SUBMITTED_URL'
              import_url.submitted_url
            when 'DOMAIN'
              import_url.domain
            when 'ISSUE_KEY'
              task.issue_key
            when 'STATUS'
              task.status
            when 'ISSUE_SUBMITTER'
              task.submitter
            when 'BAST_TASK_ID'
              task.bast_task
            when 'IMPORTED_AT'
              task.imported_at.utc.iso8601
            end
          worksheet.add_cell(row_index, col_index, cell_data)
        end
      end
    end
    workbook
  end
end
