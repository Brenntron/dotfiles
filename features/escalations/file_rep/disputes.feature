Feature: Disputes
  In order to interact with FileRep disputes
  as a user
  I will provide ways to interact with disputes
  @javascript
  Scenario: a user visits their profile page and edits their ThreatGrid and Sandbox API Keys
    Given a user with role "admin" exists and is logged in
    And I go to "/escalations/users/1"
    And I click ".edit-button"
    When I fill in "user[threatgrid_api_key]" with "Let's go."
    And I fill in "user[sandbox_api_key]" with "One more time."
    And I click "Save"
    And I wait for "3" seconds
    Then I should see "updated successfully."

  @javascript
  Scenario: an analyst tries to create a FileRep ticket
    Given a user with role "filerep user" exists and is logged in
    And the following customers exist:
    |id| name            |
    |1 | Dispute Analyst |
    And bugzilla rest api always saves
    And the user is logged into bugzilla
    And ThreatGrid API call is stubbed
    And ThreatGrid API data is stubbed
    And Reversing Labs certificates API call is stubbed
    And Sandbox API call is stubbed
    And ReversingLabs API call is stubbed
    And AMP API call is stubbed and returns a disposition of, "clean"
    And Sample Zoo API call is stubbed
    And ReversingLabs Creation Data API call is stubbed
    When I go to "/escalations/file_rep/disputes"
    And I click "#new-dispute"
    And I fill in "shas_list" with "343518b26e0a872772808605f9f28aa75f64d86a6608e1347c979d033a72cb54"
    And I click ".primary"
    Then a FileRep Ticket should have been created
    And that FileRep Ticket should have a SHA256 of "343518b26e0a872772808605f9f28aa75f64d86a6608e1347c979d033a72cb54"
    And that FileRep Ticket should have an assignee of current user
    And that FileRep Ticket should have a suggested disposition of "clean"
    And I should see "FILE REPUTATION TICKETS CREATED"

  @javascript
  Scenario: a user visits the FileRep Dispute show page and takes a ticket
    Given a user with role "filerep user" exists and is logged in
    And the following customers exist:
      |id| name            |
      |1 | Dispute Analyst |
    And vrtincoming exists
    And the following FileRep disputes exist:
      | sha256_hash                                                       |
      | 343518b26e0a872772808605f9f28aa75f64d86a6608e1347c979d033a72cb54  |
    And bugzilla rest api always saves
    And the user is logged into bugzilla
    And ThreatGrid API call is stubbed
    And Reversing Labs certificates API call is stubbed
    And Sandbox API call is stubbed
    And ReversingLabs API call is stubbed
    And AMP API call is stubbed
    And Sample Zoo API call is stubbed
    And ReversingLabs Creation Data API call is stubbed
    And I go to "/escalations/file_rep/disputes/1"
    And I dismiss modal "#msg-modal" if needed
    And I click "#research-tab-link"
    And I click "#data-resubmit-tg-cb"
    And I click "#file-rep-resubmit-evaluate-button"
    And I should see content "Successfully resubmitted to selected services: Talos Sandbox" within ".modal-dialog"

  @javascript
  Scenario: an analyst tries to create a FileRep ticket but it is flagged as a duplicate and not processed
    Given a user with role "filerep user" exists and is logged in
    And the following customers exist:
    |id| name            |
    |1 | Dispute Analyst |
    And the following FileRep disputes exist:
    | sha256_hash                                                       |
    | 343518b26e0a872772808605f9f28aa75f64d86a6608e1347c979d033a72cb54  |
    And bugzilla rest api always saves
    And the user is logged into bugzilla
    And ThreatGrid API call is stubbed
    And Reversing Labs certificates API call is stubbed
    And Sandbox API call is stubbed
    And ReversingLabs API call is stubbed
    And AMP API call is stubbed
    And Sample Zoo API call is stubbed
    And ReversingLabs Creation Data API call is stubbed
    When I go to "/escalations/file_rep/disputes"
    And I click "#new-dispute"
    And I fill in "shas_list" with "343518b26e0a872772808605f9f28aa75f64d86a6608e1347c979d033a72cb54"
    And I click ".primary"
    And I should see "The following SHA256 hashes are duplicates (no ticket created): 343518b26e0a872772808605f9f28aa75f64d86a6608e1347c979d033a72cb54"
    And I should not see "The following SHA256 hashes were created successfully:"

  @javascript
  Scenario: an analyst tries to create a FileRep ticket but one SHA25 is flagged as a duplicate and not processed, but the rest process
    Given a user with role "filerep user" exists and is logged in
    And the following customers exist:
      |id| name            |
      |1 | Dispute Analyst |
    And the following FileRep disputes exist:
      | sha256_hash                                                       |
      | 343518b26e0a872772808605f9f28aa75f64d86a6608e1347c979d033a72cb54  |
    And bugzilla rest api always saves
    And the user is logged into bugzilla
    And ThreatGrid API call is stubbed
    And Reversing Labs certificates API call is stubbed
    And Sandbox API call is stubbed
    And ReversingLabs API call is stubbed
    And AMP API call is stubbed and returns a disposition of, "clean"
    And Sample Zoo API call is stubbed
    And ReversingLabs Creation Data API call is stubbed
    When I go to "/escalations/file_rep/disputes"
    And I click "#new-dispute"
    And I fill in "shas_list" with "343518b26e0a872772808605f9f28aa75f64d86a6608e1347c979d033a72cb54 123518b26e0a872772808605f9f28aa75f64d86a6608e1347c979d033a72cb54"
    And I click ".primary"
    And I should see "Tickets have been created for the following SHA256 hashes: 123518b26e0a872772808605f9f28aa75f64d86a6608e1347c979d033a72cb54"
    And I should see "The following SHA256 hashes are duplicates (no ticket created): 343518b26e0a872772808605f9f28aa75f64d86a6608e1347c979d033a72cb54"


  @javascript
  Scenario: a user tries to visit the FileRep disputes page with a FileRep role
    Given a user with role "filerep user" exists and is logged in
    And I go to "/escalations/file_rep/disputes"
    Then I should see "File Reputation Tickets"

  @javascript
  Scenario: a user tries checks the left navigation panel without a FileRep role
    Given a user with role "webrep user" exists and is logged in
    Then I go to "/"
    And I click on element "img" with alt "Menu"
    And I click on element "img" with alt "Escalations"
    Then I wait for "1" seconds
    Then I should not see "FILE REPUTATION"
    Then I should see "WEB REPUTATION"

  @javascript
  Scenario: a user tries checks the left navigation panel with a FileRep role
    Given a user with role "filerep user" exists and is logged in
    Then I go to "/"
    And I click on element "img" with alt "Menu"
    And I click on element "img" with alt "Escalations"
    Then I wait for "1" seconds
    Then I should see "FILE REPUTATION"
    Then I should not see "WEB REPUTATION"

  @javascript
  Scenario: a user visits the FileRep disputes index page and sees all elements of the intended layout
    Given a user with role "filerep user" exists and is logged in
    And I go to "/escalations/file_rep/disputes"
    And I dismiss modal "#msg-modal" if needed
    Then I should see "STATUS"
    Then I should see "FILE NAME"
    Then I should see "SHA256"
    Then I should see "FILE SIZE"
    Then I should see "SAMPLE TYPE"
    Then I should see "AMP DISP"
    Then I should see "AMP DETECTION NAME"
    Then I should see "SANDBOX SCORE"
    Then I should see "TG SCORE"
    Then I should see "REVERSING LABS"
    Then I should see "SUGGESTED DISP"

  @javascript
  Scenario: a user disables the File Name column from the FileRep disputes index page
    Given a user with role "filerep user" exists and is logged in
    And I go to "/escalations/file_rep/disputes"
    And I dismiss modal "#msg-modal" if needed
    When I click "#file-index-table-show-columns-button"
    And I click "#file-name-checkbox"
    Then I should not see "FILE NAME"

  @javascript
  Scenario: a user enables the Resolution column from the FileRep disputes index page
    Given a user with role "filerep user" exists and is logged in
    And I go to "/escalations/file_rep/disputes"
    And I dismiss modal "#msg-modal" if needed
    When I click "#file-index-table-show-columns-button"
    And I click "#resolution-checkbox"
    Then I should see "RESOLUTION"

  @javascript
  Scenario: a user visits a FileRep Dispute Show Page and confirms that the layout is properly rendered
    Given a user with role "filerep user" exists and is logged in
    And vrtincoming exists
    And A FileRep Dispute with trait "default" exists
    When I go to "/escalations/file_rep/disputes/1"
    Then I should see "TICKET OVERVIEW"
    And I should see "Case ID"
    And I should see "0000000001"
    And I should see "FILE OVERVIEW"
    And I should see "efb947a43bfe6d0812d105f6afdeb9774f4d79254dd48f89f1e95ffdf8732928"
    And I should see "CREATE OR CHANGE DETECTION"
    And I should see "COMMUNICATION"
    And I should see "Case History"
    And I should see "Compose New Email"
    And I should see "Notes"
    And I dismiss modal "#msg-modal" if needed
    When I click "#research-tab-link"
    Then I should see "Research Data"
    And I should see "TALOS SANDBOX"
    And I should see "THREAT GRID"
    And I should see "REVERSING LABS"

  # Cucumber can't seem to load the DataTable, compromising by checking the ActiveRecord for a TG score
  @javascript
  Scenario: a user visits the FileRep Dispute Show page which launches off API calls that also sets the TG score on the record
    Given a user with role "filerep user" exists and is logged in
    And vrtincoming exists
    And A FileRep Dispute with trait "default" exists
    Then I go to "/escalations/file_rep/disputes/1"
    And I click "#msg-modal"
    And I wait for "25" seconds
    And a FileRep Ticket should have a TG score

  @javascript
  Scenario: a user visits the FileRep Dispute Show page which launches off API calls that also sets the Sandbox score on the record
    Given a user with role "filerep user" exists and is logged in
    And A FileRep Dispute with trait "default" exists
    Then I go to "/escalations/file_rep/disputes/1"
    And I click "#msg-modal"
    And I wait for "25" seconds
    And a FileRep Ticket should have a Sandbox score

  @javascript
  Scenario: a user visits the FileRep Dispute Show page which launches off API calls that also sets the RL score on the record
    Given a user with role "filerep user" exists and is logged in
    And A FileRep Dispute with trait "default" exists
    Then I go to "/escalations/file_rep/disputes/1"
    And I click "#msg-modal"
    And I wait for "25" seconds
    And a FileRep Ticket should have a RL score

  @javascript
  Scenario: a user visits the FileRep Dispute Show page and confirms that ThreatGrid data was populated
    Given a user with role "filerep user" exists and is logged in
    And vrtincoming exists
    And A FileRep Dispute with trait "default" exists
    When I go to "/escalations/file_rep/disputes/1"
    And I click "#msg-modal"
    And I click "#research-tab-link"
    And I wait for "15" seconds
    Then I should see "THREAT GRID"
    And I should see "TG Score"
    And I should see "TAGS"
    And I should see "BEHAVIORS"

  @javascript
  Scenario: a user visits the FileRep Dispute Show page and confirms that Sandbox data was populated
    Given a user with role "filerep user" exists and is logged in
    And vrtincoming exists
    And A FileRep Dispute with trait "default" exists
    When I go to "/escalations/file_rep/disputes/1"
    And I click "#msg-modal"
    And I click "#research-tab-link"
    And I wait for "15" seconds
    Then I should see "TALOS SANDBOX"
    And I should see "LATEST RUN"
    And I should see "Sandbox Score"
    And I should see "CONTACTED IPS"
    And I should see "CONTACTED DOMAIN NAMES"
    And I should see "INDICATORS OF COMPROMISE"
    And I should see "DROPPED FILES"
    And I should see "PROCESSES"


  @javascript
  Scenario: a user visits the FileRep Dispute Show page and confirms that ReversingLabs data was populated
    Given a user with role "filerep user" exists and is logged in
    And vrtincoming exists
    And A FileRep Dispute with trait "default" exists
    When I go to "/escalations/file_rep/disputes/1"
    And I click "#msg-modal"
    And I click "#research-tab-link"
    And I wait for "15" seconds
    Then I should see "REVERSING LABS"
    And I should see "FIRST SEEN"
    And I should see "MOST RECENT SCAN"
    And I should see "Scanner Results"
    And I should see "AV VENDOR"
    And I should see "TIME SCANNED"
    And I should see "RESULTS"

  @javascript
  Scenario: a user visits the FileRep Dispute index page and clicks the Naming Guide
    Given a user with role "filerep user" exists and is logged in
    When I go to "/escalations/file_rep/disputes/"
    And I click "#naming-guide"
    Then I should see "Secure Endpoint Naming Conventions Guide"

  @javascript
  Scenario: a user visits the FileRep Dispute Communications tab and tries to adds a note
    Given a user with role "filerep user" exists and is logged in
    And vrtincoming exists
    And A FileRep Dispute with trait "default" exists
    When I go to "/escalations/file_rep/disputes/1"
    And I click "#msg-modal"
    And I click "#communication-tab-link"
    And I click "#new-filerep-case-note-button"
    And I fill a content-editable field ".new-case-note-textarea" with "Here we go, again."
    And I click ".new-filerep-case-note-save-button"
    Then I should see content "Here we go, again." within ".note-block1"
    Then I should not see "Note could not created."

  @javascript
  Scenario: a user visits the FileRep Dispute index page and uses the 'My Tickets' filter
    Given a user with role "filerep user" exists and is logged in
    And A FileRep Dispute with trait "assigned" exists
    And A FileRep Dispute with trait "assigned_resolved" exists
    When I go to "/escalations/file_rep/disputes?f=my_disputes"
    Then I should see "000001"
    Then I should see "000002"

  @javascript
  Scenario: a user visits the FileRep Dispute index page and uses the 'My Open' filter
    Given a user with role "filerep user" exists and is logged in
    And A FileRep Dispute with trait "assigned" exists
    And A FileRep Dispute with trait "assigned_resolved" exists
    When I go to "/escalations/file_rep/disputes?f=my_open"
    Then I should see "000001"
    Then I should not see "000002"

  @javascript
  Scenario: a user visits the FileRep Dispute index page and uses the 'Unassigned' filter
    Given a user with role "filerep user" exists and is logged in
    And A FileRep Dispute with trait "default" exists
    And A FileRep Dispute with trait "assigned" exists
    When I go to "/escalations/file_rep/disputes?f=unassigned"
    Then I should see "000001"
    Then I should not see "000002"

  @javascript
  Scenario: a user visits the FileRep Dispute index page and uses the 'Open' filter
    Given a user with role "filerep user" exists and is logged in
    And A FileRep Dispute with trait "default" exists
    And A FileRep Dispute with trait "resolved" exists
    When I go to "/escalations/file_rep/disputes?f=open"
    Then I should see "000001"
    Then I should not see "000002"

  @javascript
  Scenario: a user visits the FileRep Dispute index page and uses the 'Closed' filter
    Given a user with role "filerep user" exists and is logged in
    And A FileRep Dispute with trait "default" exists
    And A FileRep Dispute with trait "resolved" exists
    When I go to "/escalations/file_rep/disputes?f=closed"
    Then I should see "000002"
    Then I should not see "000001"

  @javascript
  Scenario: a user visits the FileRep Dispute index page and uses the 'All' filter
    Given a user with role "filerep user" exists and is logged in
    And A FileRep Dispute with trait "default" exists
    When I go to "/escalations/file_rep/disputes?f=all"
    Then I should see "000001"

  @javascript
  Scenario: a user visits the FileRep Dispute show page and edits its status
    Given a user with role "filerep user" exists and is logged in
    And vrtincoming exists
    And A FileRep Dispute with trait "default" exists
    When I go to "/escalations/file_rep/disputes/1"
    And I click "#msg-modal"
    And I click "#show-edit-ticket-status-button"
    And I click on element "label" with accessor "for" of "file-status-escalated"
    And I click ".primary"
    Then I should see "FILE REPUTATION TICKET STATUSES UPDATED."

  @javascript
  Scenario: a user visits the FileRep Dispute show page with 'filerep manager' role and changes assignee
    Given a user with role "filerep manager" exists within org subset "file rep" and is logged in
    And vrtincoming exists
    And A FileRep Dispute with trait "unassigned" exists
    When I go to "/escalations/file_rep/disputes/1"
    And I click "#msg-modal"
    And I click "#index_change_assign"
    And I click "#button_reassign"
    Then I should not see "ERROR UPDATING TICKET."
    And I should see my username

  @javascript
  Scenario: a user visits the FileRep Dispute show page with 'filerep user' role the 'change assignee' button is hidden
    Given a user with role "filerep user" exists within org subset "file rep" and is logged in
    And vrtincoming exists
    And A FileRep Dispute with trait "unassigned" exists
    When I go to "/escalations/file_rep/disputes/1"
    And I click "#msg-modal"
    Then I should not see button with class ".ticket-owner-button"

  @javascript
  Scenario: a user visits the FileRep Dispute show page and takes a ticket
    Given a user with role "filerep user" exists and is logged in
    And vrtincoming exists
    And A FileRep Dispute with trait "unassigned" exists
    When I go to "/escalations/file_rep/disputes/1"
    And I click "#msg-modal"
    And I click ".take-ticket-button"
    Then I should not see "ERROR UPDATING TICKET."
    And I should see my username

  @javascript
  Scenario: a user visits the FileRep Dispute show page and returns a ticket
    Given a user with role "filerep user" exists and is logged in
    And vrtincoming exists
    And A FileRep Dispute with trait "unassigned" exists
    When I go to "/escalations/file_rep/disputes/1"
    And I click "#msg-modal"
    And I click ".take-ticket-button"
    Then I should not see "ERROR UPDATING TICKET."
    And I should see my username
    And I click ".return-ticket-button"
    Then I should not see "ERROR UPDATING TICKET."
    And I should not see my username
    And I should see "Unassigned"

  @javascript
  Scenario: a user visits the FileRep Dispute Communication tab and sends an email
    Given a user with role "filerep user" exists and is logged in
    And vrtincoming exists
    And A FileRep Dispute with trait "default" exists
    When I go to "/escalations/file_rep/disputes/1"
    And I click "#msg-modal"
    And I click "#communication-tab-link"
    And I click ".new-email-button"
    And I fill in "receiver" with "generic@cisco.com"
    And I fill in "subject" with "Cucumber Testing"
    And I fill in the reply textarea with "We can only hope our tests pass."
    And I click "#send-new-email"
    Then I should not see "EMAIL WAS NOT SENT"
    And I should see content "generic@cisco.com" within ".receiver-email"
    And I should see content "Cucumber Testing" within ".communication-subject"
    And I should see content "We can only hope our tests pass." within ".email-msg-content"

  @javascript
  Scenario: a user visits the FileRep Dispute index page and takes a ticket
    And a user with role "filerep user" exists and is logged in
    And A FileRep Dispute with trait "default" exists
    When I go to "/escalations/file_rep/disputes/"
    And I click "#file-index-table-show-columns-button"
    And I click "#assignee-checkbox"
    And I click ".inline-take-dispute-1"
    Then I should not see "ERROR UPDATING TICKET."
    And I should see my username

  @javascript
  Scenario: a user visits the FileRep Dispute index page and takes a ticket
    Given a user with role "filerep user" exists and is logged in
    And vrtincoming exists
    And A FileRep Dispute with trait "assigned" exists
    When I go to "/escalations/file_rep/disputes/"
    And I click "#file-index-table-show-columns-button"
    And I click "#assignee-checkbox"
    And I click ".inline-return-ticket-1"
    Then I should not see "ERROR UPDATING TICKET."
    Then I should see "Unassigned"
    And I should see my username

  # Need to stub API calls on show page
  @javascript
  Scenario: a user with the role, 'filerep manager', visits a FileRep Dispute show page and deletes someone else's comment
    Given a user with role "filerep manager" exists and is logged in
    And vrtincoming exists
    And the following users exist
    |id|
    |22|
    And A FileRep Dispute with trait "default" exists
    And the following FileRep dispute comments exist:
    |id| user_id |
    |1 | 22      |
    When I go to "/escalations/file_rep/disputes/1"
    And I click "#msg-modal"
    And I click "#communication-tab-link"
    And I click ".filerep-note-delete-button"
    And I click ".primary"
    Then no FileRep dispute comments exists

  # Need to stub API calls on show page
  @javascript
  Scenario: a user with the role, 'filerep user', visits a FileRep Dispute show page and deletes their own comment
    Given a user with role "filerep user" exists and is logged in
    And vrtincoming exists
    And A FileRep Dispute with trait "default" exists
    And the following FileRep dispute comments exist:
    |id|
    |1 |
    When I go to "/escalations/file_rep/disputes/1"
    And I click "#msg-modal"
    And I click "#communication-tab-link"
    And I click ".filerep-note-delete-button"
    And I click ".primary"
    Then no FileRep dispute comments exists

  # Need to stub API calls on show page
  @javascript
  Scenario: a user with the role, 'filerep user', visits a FileRep Dispute show page and deletes someone else's comment
    Given a user with role "filerep user" exists and is logged in
    And vrtincoming exists
    And the following users exist
    |id|
    |22|
    And A FileRep Dispute with trait "default" exists
    And the following FileRep dispute comments exist:
    |id| user_id |
    |1 |    22   |
    When I go to "/escalations/file_rep/disputes/1"
    And I click "#msg-modal"
    And I click "#communication-tab-link"
    And I click ".filerep-note-delete-button"
    And I click ".primary"
    Then I should see "Unable to delete a note written by another user."

  @javascript
  Scenario: a user creates a new FileRep Dispute through the form and the ticket is auto-resolved
    Given a user with role "filerep user" exists and is logged in
    And the following customers exist:
    |id| name            |
    |1 | Dispute Analyst |
    And the user is logged into bugzilla
    And bugzilla rest api always saves
    And ThreatGrid API call is stubbed
    And Reversing Labs certificates API call is stubbed
    And Sandbox API call is stubbed
    And ReversingLabs API call is stubbed
    And AMP API call is stubbed and returns a disposition of, "malicious"
    And Sample Zoo API call is stubbed
    And ReversingLabs Creation Data API call is stubbed
    When I go to "/escalations/file_rep/disputes/"
    And I click "#new-dispute"
    And I fill in "shas_list" with "b7d2790048f5cacbf03ee9e36a6b6bc9ffabfc1e449bde0c507d3667064ea791"
    And I select "Malicious" from "disposition_suggested"
    And I click "#file_rep_submit"
    And I go to "/escalations/file_rep/disputes/"
    Then I should see content "RESOLVED" within "#status_10101"
    And I should see content "malicious" within first element of class ".malicious"
    And FileRep Dispute has the appropriate 'resolution_comment' for auto-resolved entries

  @javascript
  Scenario: an entry with no sample is not auto-resolved
    Given a user with role "filerep user" exists and is logged in
    And the following customers exist:
      |id| name            |
      |1 | Dispute Analyst |
    And the user is logged into bugzilla
    And bugzilla rest api always saves
    And ThreatGrid API call is stubbed
    And ThreatGrid API data is stubbed
    And Reversing Labs certificates API call is stubbed
    And The file is not in ReversingLabs
    And Sandbox API call is stubbed
    And The sample does not exist in the sandbox
    And ReversingLabs API call is stubbed
    And AMP API call is stubbed and returns a disposition of, "malicious"
    And The file is not in the sample zoo
    And ReversingLabs Creation Data API call is stubbed
    When I go to "/escalations/file_rep/disputes/"
    And I click "#new-dispute"
    And I fill in "shas_list" with "b7d2790048f5cacbf03ee9e36a6b6bc9ffabfc1e449bde0c507d3667064ea791"
    And I select "Clean" from "disposition_suggested"
    And I click "#file_rep_submit"
    And I go to "/escalations/file_rep/disputes/"
    Then I should see content "NEW" within "#status_10101"
    When I go to "/escalations/file_rep/disputes/10101"
    And I click "#auto_resolve_log_button"
    Then I should see "Setting Status To New as there is no sample."
    And FileRep Dispute does not have a resolution comment


  @javascript
  Scenario: a user sees a properly worded time stamp on a comment under the Communications tab
    Given a user with role "filerep user" exists and is logged in
    And vrtincoming exists
    And A FileRep Dispute with trait "assigned" exists
    And A FileRep Dispute comment with trait "new" exists
    When I go to "/escalations/file_rep/disputes/1"
    And I click "#msg-modal"
    And I click "#communication-tab-link"
    Then I should see content "seconds ago." within ".author-notation"
    Then I should not see "1 hour"

  @javascript
  Scenario: a user with the role 'amp pattern namer' visits the Secure Endpoint Naming Convention page and sees the edit button
    Given a user with role "amp pattern namer" exists and is logged in
    When I go to "/escalations/file_rep/naming_guide"
    Then I should see "EDIT SECURE ENDPOINT NAMING CONVENTIONS"

  @javascript
  Scenario: a user with the role 'amp pattern namer' visits the Secure Endpoint Naming Convention page and clicks the edit button and a blank row is created
    Given a user with role "amp pattern namer" exists and is logged in
    When I go to "/escalations/file_rep/naming_guide"
    And I click "#amp-edit-button"
    And I click "#amp-new-button"
    Then I should see content "" within ".amp-pattern"
    And I should see content "" within ".amp-example"
    And I should see content "" within ".engine-description"
    And I should see content "" within ".private-engine-description"
    And I should see content "" within ".amp-contact"
    And I should see content "" within ".amp-notes"
    And I should see content "" within ".amp-public-notes"

  @javascript
  Scenario: a user with the role 'amp pattern namer' visits the Secure Endpoint Naming Convention page and saves an entry
    Given a user with role "amp pattern namer" exists and is logged in
    When I go to "/escalations/file_rep/naming_guide"
    And I click "#amp-edit-button"
    And I click "#amp-new-button"
    And I fill in element, ".code-input" with "Code"
    And I fill in element, ".example-input" with "Example"
    And I fill in element, ".engine-description .table-form-content textarea" with "Description"
    And I fill in element, ".private-engine-description .table-form-content textarea" with "Private Description"
    And I fill in element, ".amp-contact .table-form-content textarea" with "Contact"
    And I fill in element, ".amp-notes .table-form-content textarea" with "Notes"
    And I fill in element, ".amp-public-notes .table-form-content textarea" with "Public Notes"
    And I click "#amp-save-button"
    Then I should see "THE FOLLOWING SECURE ENDPOINT NAMING CONVENTIONS HAVE BEEN CREATED:"
    And I should see content "Code" within ".amp-pattern .table-code"
    And I should see content "Example" within ".amp-example"
    And I should see content "Description" within ".engine-description"
    And I should see content "Contact" within ".amp-contact"
    And I should see content "Notes" within ".amp-notes"
    And I should see content "Public Notes" within ".amp-public-notes"

  @javascript
  Scenario: a user with the role 'amp pattern namer' visits the Secure Endpoint Naming Convention page and deletes an entry
    Given a user with role "amp pattern namer" exists and is logged in
    And the following Secure Endpoint Naming Conventions exist:
      |private_engine_description|
      |Private                   |
    When I go to "/escalations/file_rep/naming_guide"
    And I click "#amp-edit-button"
    And I click ".delete-button"
    Then I should see "STAGED FOR DELETION: Pattern"
    When I click "#amp-save-button"
    Then I wait for "2" seconds
    And I should see "SECURE ENDPOINT NAMING CONVENTION(S) BELOW HAS BEEN DELETED"

  @javascript
  Scenario: a user with the role 'amp pattern namer' visits the Secure Endpoint Naming Convention page and edits an entry
    Given a user with role "amp pattern namer" exists and is logged in
    And the following Secure Endpoint Naming Conventions exist:
      |private_engine_description|
      |Private                   |
    When I go to "/escalations/file_rep/naming_guide"
    And I click "#amp-edit-button"
    And I fill in element, ".code-input" with "It's"
    And I fill in element, ".example-input" with "Another"
    And I fill in element, ".engine-description .table-form-content textarea" with "Cucumber"
    And I fill in element, ".private-engine-description .table-form-content textarea" with "Test"
    And I fill in element, ".amp-contact .table-form-content textarea" with "Now"
    And I fill in element, ".amp-notes .table-form-content textarea" with "Tell"
    And I fill in element, ".amp-public-notes .table-form-content textarea" with "Everyone"
    And I click "#amp-save-button"
    #Then take a screenshot
    Then I should see "SECURE ENDPOINT NAMING CONVENTIONS HAVE BEEN UPDATED"
    When I go to "/escalations/file_rep/naming_guide"
    And I should see content "It's" within ".amp-pattern"
    And I should see content "Another" within ".amp-example"
    And I should see content "Cucumber" within ".engine-description"
    And I should see content "Test" within ".private-engine-description"
    And I should see content "Tell" within ".amp-notes"
    And I should see content "Everyone" within ".amp-public-notes"
    And I should see content "Now" within ".amp-contact"

  @javascript
  Scenario: left nav links should apply filter if the filter was set before
    Given a user with role "filerep user" exists and is logged in
    And A FileRep Dispute with trait "assigned" exists
    And A FileRep Dispute with trait "assigned_resolved" exists
    When I go to "/escalations/file_rep/disputes?f=my_open"
    Then I should see "000001"
    Then I should not see "000002"
    When I click "#nav-trigger-label"
    And I click "Escalations"
    And I click "#amp-icon-link"
    Then I should see "000001"
    Then I should not see "000002"
    When I click "#nav-trigger-label"
    And I click "Escalations"
    And I click "#amp-link"
    Then I should see "000001"
    Then I should not see "000002"

  @javascript
  Scenario: top nav links should apply filter if the filter was set before
    Given a user with role "filerep user" exists and is logged in
    And A FileRep Dispute with trait "assigned" exists
    And A FileRep Dispute with trait "assigned_resolved" exists
    When I go to "/escalations/file_rep/disputes?f=my_open"
    Then I should see "000001"
    Then I should not see "000002"
    When I click "#queue"
    Then I should see "000001"
    Then I should not see "000002"

  @javascript
  Scenario: a user uses advanced search with 'Platform' as a search criteria
    Given a user with role "filerep user" exists and is logged in
    And platforms with all traits exist
    And the following FileRep disputes exist:
      | sha256_hash                                                       | platform_id |
      | 343518b26e0a872772808605f9f28aa75f64d86a6608e1347c979d033a72cb54  | 5           |
      | addd44ee803082c4667bae68284e316f1a799b72ecbdaae38097ba2c4ccb9d16  | 1           |
    When I goto "escalations/file_rep/disputes?f=open"
    And I click "#advanced-search-button"
    And I click "#add-search-items-button"
    And I click "#platform-cb"
    And I wait for "5" seconds
    And I fill in selectized of element "#platform-input" with "['5']"
    Then I click "#cancel-add-criteria"
    Then I click "#submit-advanced-search"
    And I should see "PLATFORMS: Filerep"
    Then I should see "000001"
    And I should not see "000002"

