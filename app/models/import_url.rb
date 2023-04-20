class ImportUrl < ApplicationRecord
  belongs_to :jira_import_task
  belongs_to :complaint, optional: true

  def to_hash
    {
        url: submitted_url,
        domain: domain,
        complaint_id: complaint_id,
        imported: bast_verdict == "1" ? "Imported" : "Not Imported",
        verdict_reason: verdict_reason
    }
  end
end
