class UserPreference < ApplicationRecord
  belongs_to :user

  WEB_REP_COLUMNS = 'WebRepColumns'

  # Fixes https://jira.talos.cisco.com/browse/WEB-8027
  DEFAULT_WEB_REP_COLUMNS = '{
    "priority": true,
    "case-id": true,
    "status": true,
    "resolution": false,
    "submission-type": false,
    "dispute": true,
    "owner": true,
    "time-submitted": true,
    "age": true,
    "case-origin": false,
    "submitter-type": false,
    "submitter-org": false,
    "submitter-domain": false,
    "contact-name": false,
    "contact-email": false,
    "status-comment": false,
    "last-updated": true,
    "platform": true
  }'
end
