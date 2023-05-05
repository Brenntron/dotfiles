class JiraImportTaskDatatable < AjaxDatatablesRails::ActiveRecord
  def initialize(params)
    super(params, {})
  end

  def view_columns
    @view_columns ||= {
        id:                          { source: "JiraImportTask.id", cond: :eq },
        issue_key:                   { source: "JiraImportTask.issue_key", data: :issue_key, cond: :like },
        status:                      { source: "JiraImportTask.status", data: :status, cond: :like },
        result:                      { source: "JiraImportTask.result", data: :result, cond: :like},
        submitter:                   { source: "JiraImportTask.submitter", data: :submitter, cond: :like },
        bast_task:                   { source: "JiraImportTask.bast_task", data: :bast_task, searchable: false },
        imported_at:                 { source: "JiraImportTask.imported_at", data: :imported_at, searchable: false },
        created_at:                  { source: "JiraImportTask.created_at", data: :created_at, searchable: false },
        updated_at:                  { source: "JiraImportTask.updated_at", data: :updated_at, searchable: false },
        total_urls:                  { source: "JiraImportTask.total_urls", data: :total_urls, searchable: false },
        unimported_urls:             { source: "JiraImportTask.unimported_urls", data: :unimported_urls, searchable: false},
        imported_urls:               { source: "JiraImportTask.imported_urls", data: :imported_urls, searchable: false},
        issue_summary:               { source: "JiraImportTask.issue_summary", data: :issue_summary, searchable: false},
        issue_description:           { source: "JiraImportTask.issue_description", data: :issue_description, searchable: false},
        issue_status:                { source: "JiraImportTask.issue_status", data: :issue_status, searchable: false},
        issue_platform:              { source: "JiraImportTask.issue_platform", data: :issue_platform, searchable: false}
    }
  end

  def data
    records.map do |record|
      {
          id: record.id,
          issue_key: record.issue_key,
          status: record.status,
          result: record.result,
          submitter: record.submitter,
          bast_task: record.bast_task,
          imported_at: record.imported_at,
          created_at: record.created_at,
          updated_at: record.updated_at,
          total_urls: record.import_urls.count,
          unimported_urls: record.unimported_urls.count,
          imported_urls: record.imported_urls.count,
          DT_RowId: record.id,
          issue_summary: record.issue_summary,
          issue_description: record.issue_description,
          issue_status: record.issue_status,
          issue_platform: record.issue_platform
      }
    end
  end

  def get_raw_records
    JiraImportTask.all
  end
end
