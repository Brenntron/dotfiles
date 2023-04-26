class ImportUrl < ApplicationRecord
  belongs_to :jira_import_task
  belongs_to :complaint, optional: true

  def to_hash
    entry = ComplaintEntry.where(complaint_id:complaint_id).first if complaint_id.present?
    age = ComplaintEntry.first_two_time_layers(time_ago_in_words(entry.created_at.to_time, {scope: 'datetime.distance_in_words', include_seconds: false})) if entry.present?
    assignee = User.find(entry&.user_id).cvs_username if entry.present?

    {
        url: submitted_url,
        domain: domain || '-',
        complaint_id: complaint_id || '-',
        imported: bast_verdict == "1" ? "Imported" : "Not Imported",
        verdict_reason: verdict_reason,
        entry_id: entry&.id || '-',
        age: age || '-',
        status:entry&.status || '-',
        resolution:entry&.resolution || '-',
        resolution_time:entry&.case_resolved_at || '-',
        assignee: assignee || '-',
        category:entry&.category || '-'
    }
  end
end
