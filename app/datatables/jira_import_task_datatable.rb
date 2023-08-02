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
        total_urls:                  { source: "JiraImportTask.total_urls", data: :total_urls, searchable: false, orderable: false },
        unimported_urls:             { source: "JiraImportTask.unimported_urls", data: :unimported_urls, searchable: false, orderable: false},
        imported_urls:               { source: "JiraImportTask.imported_urls", data: :imported_urls, searchable: false, orderable: false},
        issue_status:                { source: "JiraImportTask.issue_status", data: :issue_status, searchable: false},
        issue_summary:               { source: "JiraImportTask.issue_summary", data: :issue_summary, searchable: false},
        issue_description:           { source: "JiraImportTask.issue_description", data: :issue_description, searchable: false},
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
          issue_status: record.issue_status,
          issue_summary: record.issue_summary,
          issue_description: record.issue_description,
          issue_platform: record.issue_platform,
          DT_RowId: record.id
      }
    end
  end

  def get_raw_records
    JiraImportTask.all
  end

  def sort_records(records)
    case datatable.orders.first.column.sort_query
    when 'jira_import_tasks.result'
      records.order("status #{datatable.orders.first.direction}")
    when 'jira_import_tasks.issue_key'
      if datatable.orders.first.direction == 'ASC'
        record_ids = records.sort_by { |record| record.issue_key.split("-").last.to_i }.map(&:id)
      else
        record_ids = records.sort_by { |record| record.issue_key.split("-").last.to_i }.reverse.map(&:id)
      end

      order_clause = "CASE id "
      record_ids.each_with_index do |value, index|
        order_clause << "WHEN #{value} THEN #{index} "
      end
      order_clause << "END"

      JiraImportTask.where(id: records.map(&:id)).order(Arel.sql(order_clause))
    when 'jira_import_tasks.issue_status'
      if datatable.orders.first.direction == 'ASC'
        record_ids = records.sort_by {|record| record.issue_status}.map(&:id)
      else
        record_ids = records.sort_by {|record| record.issue_status}.reverse.map(&:id)
      end

      order_clause = "CASE id "
      record_ids.each_with_index do |value, index|
        order_clause << "WHEN #{value} THEN #{index} "
      end
      order_clause << "END"

      JiraImportTask.where(id: records.map(&:id)).order(Arel.sql(order_clause))
    else
      super
    end
  end
end