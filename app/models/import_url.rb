class ImportUrl < ApplicationRecord
  belongs_to :jira_import_task
  belongs_to :complaint, optional: true

  def to_hash
    entry_id = ComplaintEntry.where(complaint_id:complaint_id).first&.id if complaint_id.present?
    {
        url: submitted_url,
        domain: domain,
        complaint_id: complaint_id,
        imported: bast_verdict == "1" ? "Imported" : "Not Imported",
        verdict_reason: verdict_reason,
        entry_id: entry_id
    }
  end
end
