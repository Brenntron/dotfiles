class ImportUrl < ApplicationRecord
  belongs_to :jira_import_task
  belongs_to :complaint, optional: true
end
