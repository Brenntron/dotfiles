class JiraImportTask < ApplicationRecord
  has_many :import_urls

  validates :issue_key, presence: true, uniqueness: true

  STATUS_COMPLETE = "Complete"
  STATUS_FAILURE = "Failure"
  STATUS_PENDING = "Pending"

  VALID_FILE_TYPE = "text/csv"

  #Read CSV from Jira and send URLs to Bast
  def process_import
    update(imported_at: Time.now)

    issue = JiraRest::Issue.new(issue_key)
    attachments = issue.attachments_data
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
        import_urls.find_or_create_by(submitted_url: url)
      end

      begin
        response = Bast::Base.create_task(urls)
      rescue ApiRequester::ApiRequester::ApiRequesterError => e
        update(status: STATUS_FAILURE, result: e.message)
      end

      update(status: STATUS_PENDING, bast_task: response["task_id"])

    else
      update(status: STATUS_FAILURE, result: "Invalid file type: #{attachment_to_process[:type]}")
    end
  end
  handle_asynchronously :process_import, :queue => "process_jira_import", :priority => 1
end
