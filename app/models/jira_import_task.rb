class JiraImportTask < ApplicationRecord
  has_many :import_urls

  validates :issue_key, presence: true, uniqueness: true
  validates :bast_task, uniqueness: true

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
      raw_data = attachment_to_process[:content]
      filtered_data = raw_data.map {|m| m.gsub("\"", '').gsub(',', '').strip}.reject {|r| r.blank?}
      filtered_data.each do |url|
        import_urls.find_or_create_by(submitted_url: url)
      end

      begin
        response = Bast::BastApi.create_task(filtered_data)
      rescue Bast::BastError => e
        update(status: STATUS_FAILURE, result: e.message)
      end

      update(status: STATUS_PENDING, bast_task: response["task_id"])

    else
      update(status: STATUS_FAILURE, result: "Invalid file type: #{attachment_to_process[:type]}")
    end
  end
  handle_asynchronously :process_import, :queue => "process_jira_import", :priority => 1
end
