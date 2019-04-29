Feature: Disputes
  In order to interact with FileRep disputes
  as a user
  I will provide ways to interact with disputes

  @javascript
  Scenario: a user visits their profile page and edits their ThreatGrid and Sandbox API Keys
    Given a user with role "admin" exists and is logged in
    And I go to "/users/1"
    When I fill in "user_threatgrid_api_key" with "Let's go."
    And I fill in "user_sandbox_api_key" with "One more time."
    And I click ".btn-success"
    And I wait for "3" seconds
    Then I should see "updated successfully."

  @javascript
  Scenario: an analyst tries to create a FileRep ticket
    Given a user with role "filerep user" exists and is logged in
    And I go to "/escalations/file_rep/disputes"
    Then I click "#new-dispute"
    Then I fill in "shas_list" with "343518b26e0a872772808605f9f28aa75f64d86a6608e1347c979d033a72cb54"
    Then I click ".primary"
    Then I wait for "30" seconds
    Then a FileRep Ticket should have been created

  @javascript
  Scenario: a user tries to visit the FileRep disputes page without a FileRep role
    Given a user with role "other user" exists and is logged in
    And I go to "/escalations/file_rep/disputes"
    Then I should see "You are not authorized"

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
    When I click "#file-index-table-show-columns-button"
    And I click "#file-name-checkbox"
    Then I should not see "FILE NAME"

  @javascript
  Scenario: a user enables the Resolution column from the FileRep disputes index page
    Given a user with role "filerep user" exists and is logged in
    And I go to "/escalations/file_rep/disputes"
    When I click "#file-index-table-show-columns-button"
    And I click "#resolution-checkbox"
    Then I should see "RESOLUTION"

  @javascript
  Scenario: a user visits a FileRep Dispute Show Page and confirms that the layout is properly rendered
    Given a user with role "filerep user" exists and is logged in
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
    When I click "#research-tab-link"
    Then I should see "Research Data"
    And I should see "TALOS SANDBOX"
    And I should see "THREAT GRID"
    And I should see "REVERSING LABS"

  # Cucumber can't seem to load the DataTable, compromising by checking the ActiveRecord for a TG score
  @javascript
  Scenario: a user visits the FileRep Dispute Show page which launches off API calls that also sets the TG score on the record
    Given a user with role "filerep user" exists and is logged in
    And A FileRep Dispute with trait "default" exists
    Then I go to "/escalations/file_rep/disputes/1"
    And I wait for "25" seconds
    And a FileRep Ticket should have a TG score

  @javascript
  Scenario: a user visits the FileRep Dispute Show page which launches off API calls that also sets the Sandbox score on the record
    Given a user with role "filerep user" exists and is logged in
    And A FileRep Dispute with trait "default" exists
    Then I go to "/escalations/file_rep/disputes/1"
    And I wait for "25" seconds
    And a FileRep Ticket should have a Sandbox score

  @javascript
  Scenario: a user visits the FileRep Dispute Show page which launches off API calls that also sets the RL score on the record
    Given a user with role "filerep user" exists and is logged in
    And A FileRep Dispute with trait "default" exists
    Then I go to "/escalations/file_rep/disputes/1"
    And I wait for "25" seconds
    And a FileRep Ticket should have a RL score

  @javascript
  Scenario: a user visits the FileRep Dispute Show page and confirms that ThreatGrid data was populated
    Given a user with role "filerep user" exists and is logged in
    And A FileRep Dispute with trait "default" exists
    When I go to "/escalations/file_rep/disputes/1"
    And I click "#research-tab-link"
    And I wait for "25" seconds
    Then I should see "THREAT GRID"
    And I should see "TG Score"
    And I should see "TAGS"
    And I should see "BEHAVIORS"

  @javascript
  Scenario: a user visits the FileRep Dispute Show page and confirms that Sandbox data was populated
    Given a user with role "filerep user" exists and is logged in
    And A FileRep Dispute with trait "default" exists
    When I go to "/escalations/file_rep/disputes/1"
    And I click "#research-tab-link"
    And I wait for "25" seconds
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
    And A FileRep Dispute with trait "default" exists
    When I go to "/escalations/file_rep/disputes/1"
    And I click "#research-tab-link"
    And I wait for "25" seconds
    Then I should see "REVERSING LABS"
    And I should see "FIRST SEEN"
    And I should see "MOST RECENT SCAN"
    And I should see "Scanner Results"
    And I should see "AV VENDOR"
    And I should see "TIME SCANNED"
    And I should see "RESULTS"

  @javascript
  Scenario: a user visits the FileRep Dispute Show page and confirms that ReversingLabs data was populated
    Given a user with role "filerep user" exists and is logged in
    When I go to "/escalations/file_rep/disputes/"
    And I click "#naming-guide"
    Then I should see "AMP Naming Conventions Guide"

  # Unable to reach Communications tab due to JavaScript errors caused by Poltergeist 2.1.1's incompatibility with JavaScript ES6
  # Resolved by switching to Selenium
  @javascript
  Scenario: a user visits the FileRep Dispute Communications tab and tries to adds a note
    Given a user with role "filerep user" exists and is logged in
    And A FileRep Dispute with trait "default" exists
    When I go to "/escalations/file_rep/disputes/1"
    And I click "#communication-tab-link"
    And I click "#new-case-note-button"
    And I fill a content-editable field ".new-case-note-textarea" with "Here we go, again."
    And I click ".new-case-note-save-button"
    And I go to "/escalations/file_rep/disputes/1"
    Then I should see "Here we go, again."

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
    And A FileRep Dispute with trait "default" exists
    When I go to "/escalations/file_rep/disputes/1"
    And I click "#show-edit-ticket-status-button"
    And I click on element "input" with accessor "value" of "RESEARCHING"
    And I click ".primary"
    Then I should see "RESEARCHING"

  @javascript
  Scenario: a user visits the FileRep Dispute show page and changes assignee
    Given a user with role "filerep user" exists within org subset "file rep" and is logged in
    And A FileRep Dispute with trait "default" exists
    When I go to "/escalations/file_rep/disputes/1"
    And I click "#index_change_assign"
    And I click "#button_reassign"
    Then I should not see "ERROR UPDATING TICKET."
    And I should see my username

  @javascript
  Scenario: a user visits the FileRep Dispute show page and takes a ticket
    Given the following users exist
    |id| cvs_username |
    |1 | vrtincom     |
    And a user with role "filerep user" exists and is logged in
    And A FileRep Dispute with trait "default" exists
    When I go to "/escalations/file_rep/disputes/1"
    And I click ".take-ticket-button"
    Then I should not see "ERROR UPDATING TICKET."
    And I should see my username

  @javascript
  Scenario: a user visits the FileRep Dispute show page and returns a ticket
    Given the following users exist
    |id| cvs_username |
    |1 | vrtincom     |
    And a user with role "filerep user" exists and is logged in
    And A FileRep Dispute with trait "default" exists
    When I go to "/escalations/file_rep/disputes/1"
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
    And A FileRep Dispute with trait "default" exists
    When I go to "/escalations/file_rep/disputes/1"
    And I click "#communication-tab-link"
    And I click ".new-email-button"
    And I fill in "receiver" with "ancheng3@cisco.com"
    And I fill in "subject" with "Cucumber Testing"
    And I fill in the reply textarea with "We can only hope our tests pass."
    And I click "#send-new-email"
    Then I should not see "EMAIL WAS NOT SENT"
    And I should see "ancheng3@cisco.com"
    And I should see "Cucumber Testing"

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
    Given the following users exist
    |id| cvs_username |
    |1 | vrtincom     |
    And a user with role "filerep user" exists and is logged in
    And A FileRep Dispute with trait "assigned" exists
    When I go to "/escalations/file_rep/disputes/"
    And I click "#file-index-table-show-columns-button"
    And I click "#assignee-checkbox"
    And I click ".inline-return-ticket-1"
    Then I should not see "ERROR UPDATING TICKET."
    Then I should see "Unassigned"
