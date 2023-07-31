class ImportUrl < ApplicationRecord
  belongs_to :jira_import_task
  belongs_to :complaint, optional: true
  has_many :complaint_entries, through: :complaint

  def url_dt_format
    entry = ComplaintEntry.where(complaint_id:complaint_id).first if complaint_id.present?
    age = ComplaintEntry.first_two_time_layers(time_ago_in_words(entry.created_at.to_time, {scope: 'datetime.distance_in_words', include_seconds: false})) if entry.present?

    assignee = User.find(entry&.user_id).cvs_username if entry.present?

    imported = bast_verdict == "1" ? "Imported" : "Not Imported"
    if verdict_reason
      imported += " - #{verdict_reason}"
    end
    [
      '',                                                          #empty val for checkbox col
      entry&.is_important,                                         #important icon
      submitted_url,                                               #url
      domain,                                                      #domain
      entry&.id,                                                   #entry_id
      complaint_id,                                                #complaint_id
      entry&.status,                                               #status
      entry&.resolution,                                           #resolution
      entry&.case_resolved_at,                                     #resolution_time
      entry&.category,                                             #category
      assignee,                                                    #assignee
      age,                                                         #age
      imported                                                     #verdict_reason
    ]
  end
end
