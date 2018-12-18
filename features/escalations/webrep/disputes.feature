Feature: Disputes
  In order to interact with disputes
  as a user
  I will provide ways to interact with disputes

  @javascript
  Scenario: a user visits the duplicate cases tab and sees a table of duplicate cases
    Given a user with role "webrep user" exists and is logged in
    Given the following disputes exist and have entries:
    |id|
    |1 |
    Given a dispute exists and is related to disputes with ID, "1":
    And I go to "/escalations/webrep/disputes/1"
    Then I click "#related-tab-link"
    Then I should see "0000000002"

  @javascript
  Scenario: the last submitted field returns data
    Given a user with role "admin" exists and is logged in
    And the following disputes exist and have entries:
      |id|
      | 1|
      | 2|
    Then I go to "/escalations/webrep/disputes/1"
    Then I click link "Research"
    Then Expect date in element "#last-submitted" to equal today's date

  @javascript
  Scenario: a user can see data in the Submitter Type column
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |id|submitter_type|
      |1 |CUSTOMER      |
    Then I goto "escalations/webrep/"
    When I trigger-click "#table-show-columns-button"
    And I trigger-click "#submitter-type-checkbox"
    Then I should see table header with id "submitter-type"
    Then I should see "CUSTOMER"

  @javascript
  Scenario: a user takes a dispute and status is updated to assigned
    Given a user with role "webrep user" exists with cvs_username, "Cucumber", exists and is logged in
    Given the following users exist
    |id|cvs_username|
    | 3|  vrtincom  |
    And the following disputes exist:
    |id|user_id|
    | 2|   3   |
    When I goto "escalations/webrep/disputes"
    And I click ".take-dispute-2"
    Then I see "ASSIGNED" in element "#status_2"
    Then I should see user, "Cucumber", in element "#owner_2"

  @javascript
  Scenario: a user takes a dispute, returns a dispute, and takes the dispute again
    Given a user with role "webrep user" exists with cvs_username, "Cucumber", exists and is logged in
    Given the following users exist
      |id|cvs_username|
      |3 |vrtincom    |
    And the following disputes exist:
      |id|user_id|
      |2 |3      |
    When I goto "escalations/webrep/disputes"
    And I click ".take-dispute-2"
    Then I see "ASSIGNED" in element "#status_2"
    Then I see "Cucumber" in element "#owner_2"
    When I click ".return-ticket-2"
    Then I see "NEW" in element "#status_2"
    Then I see "Unassigned" in element "#owner_2"
    When I click ".take-dispute-2"
    Then I see "ASSIGNED" in element "#status_2"
    Then I see "Cucumber" in element "#owner_2"

  @javascript
  Scenario: a user edits a dispute entry's status and saves their changes
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
    |id|
    |1 |
    When I goto "escalations/webrep/disputes/1/"
    And I click "#research-tab-link"
    And I click ".inline-edit-entry-button"
    And I click "#entry_status_button_1"
    And I click "#RE-OPENED"
    And I trigger-click ".save-all-changes"
    Then I wait for "3" seconds
    Then I should see "RE-OPENED"

  @javascript
  Scenario: when the user encounters a situation in which no results exists (therefore none returned), an error modal should display
  Given a user with role "webrep user" exists and is logged in
  When I goto "escalations/webrep/disputes"
  Then I should see "NO TICKETS MATCHING FILTER OR SEARCH."

  @javascript
  Scenario: a user adds a dispute as a related case using the tooltip button
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
    |id|
    |1 |
    And the following disputes exist:
    |id|
    |2 |
    When I goto "escalations/webrep/disputes"
    Given I check "cbox0000000001"
    And I click ".mark-related-button"
    And I fill in "dispute_id" with "2"
    And I click "#set-related-dispute-submit-button_button_related_dispute"
    And I wait for "5" seconds
    Then check if dispute id, "1", has a related_id of "2"

  @javascript
  Scenario: a user uses advanced search filter (Submitted Older/Modified Older) and exports to csv
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
    |id|
    |1 |
    When I goto "escalations/webrep/disputes?f=open"
    And I click "#advanced-search-button"
    And I click "#add-search-items-button"
    And I click "#submitted-older-cb"
    And I click "#modified-older-cb"
    And I click "#add-search-criteria"
    Then I trigger-click ".export-button"
    Then I wait for "3" seconds
    Then I should receive a file of type "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"'

  @javascript
  Scenario: a user adds and selects columns from the Column drop-down
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |id|
      |1 |
    When I goto "escalations/webrep/disputes?f=open"
    And I trigger-click "#table-show-columns-button"
    And I trigger-click "#case-id-checkbox"
    And I trigger-click "#status-checkbox"
    And I trigger-click "#submitter-type-checkbox"
    And I trigger-click "#submitter-org-checkbox"
    And I trigger-click "#submitter-domain-checkbox"
    And I trigger-click "#contact-name-checkbox"
    And I trigger-click "#contact-email-checkbox"
    When I goto "escalations/webrep/disputes?f=open"
    Then I wait for "5" seconds
    Then I should not see "CASE ID"
    Then I should not see "STATUS"
    Then I should see "SUBMITTER TYPE"
    Then I should see "SUBMITTER ORG"
    Then I should see "SUBMITTER DOMAIN"
    Then I should see "CONTACT NAME"
    Then I should see "CONTACT EMAIL"

  @javascript
  Scenario: a users uses advanced search with 'Contact Name' as a search criteria
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
    |id| submission_type|
    |1 | w              |
    When I goto "escalations/webrep/disputes?f=all"
    And I click "#advanced-search-button"
    And I click "#add-search-items-button"
    And I click "#name-cb"
    And I click "#add-search-criteria"
    Then I fill in "name-input" with "Bob Jones"
    Then I click "#submit-advanced-search"
    And I trigger-click "#advanced-search-button"
    Then I wait for "5" seconds
    Then I should see "talosintelligence.com"
    Then I should see "0000000001"


  @javascript
  Scenario: a users uses advanced search with 'Contact Email' as a search criteria
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |id| submission_type|
      |1 | w              |
    When I goto "escalations/webrep/disputes?f=all"
    And I click "#advanced-search-button"
    And I click "#add-search-items-button"
    And I click "#email-cb"
    And I click "#add-search-criteria"
    Then I fill in "email-input" with "bob@bob.com"
    Then I click "#submit-advanced-search"
    And I trigger-click "#advanced-search-button"
    Then I wait for "5" seconds
    Then I should see "talosintelligence.com"
    Then I should see "0000000001"

  @javascript
  Scenario: a users uses advanced search with 'Company' as a search criteria
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |id| submission_type|
      |1 | w              |
    When I goto "escalations/webrep/disputes?f=all"
    And I click "#advanced-search-button"
    And I click "#add-search-items-button"
    And I click "#company-cb"
    And I click "#add-search-criteria"
    Then I fill in "company-input" with "Bobs Burgers"
    Then I click "#submit-advanced-search"
    And I trigger-click "#advanced-search-button"
    Then I wait for "5" seconds
    Then I should see "talosintelligence.com"
    Then I should see "0000000001"

  @javascript
  Scenario: a user tries to export selected dispute entries
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |id| submission_type|
      |1 | w              |
    When I goto "escalations/webrep/disputes?f=all"
    And I click "#expand-all-index-rows"
    And I trigger-click ".dispute-entry-checkbox_1"
    And I click ".export-button"
    Then I wait for "3" seconds
    Then I should receive a file of type "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

  @javascript
  Scenario: a user tries to export selected dispute entries on the Research tab
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
    |id|
    |1 |
    When I goto "/escalations/webrep/disputes/1"
    And I trigger-click "#research-tab-link"
    And I trigger-click ".dispute_check_box"
    And I click ".export-button"
    Then I wait for "3" seconds
    Then I should receive a file of type "application/octet-stream"

  @javascript
  Scenario: A user creates a new resolution message template
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |id  |
      |5370|
    And I goto "/escalations/webrep/disputes/5370"
    And I click ".mng-resolution-message-templates-button"
    And I click "#create-resolution-message-template"
    And I fill in "new-resolution-message-template-name" with "Testimony"
    And I fill in "new-resolution-message-template-desc" with "Apples and Carrots"
    And I fill in "new-resolution-message-template-body" with "Teenage Mutant Ninja Turtles"
    When I click "#save-resolution-message-template"
    And I wait for "3" seconds
    Then I should see "RESOLUTION MESSAGE TEMPLATE CREATED."

  @javascript
  Scenario: A user selects a resolution message template and updates it
    Given a user with role "webrep user" exists and is logged in
    And a resolution message template exists
    And the following disputes exist and have entries:
      |id  |
      |5370|
    And I goto "/escalations/webrep/disputes/5370"
    And I click ".mng-resolution-message-templates-button"
    Then I should see "Templar"
    Then I should see "Axe"
    Given I click ".edit-resolution-message-template"
    Then I wait for "3" seconds
    Then I should see content "This is a test." within "#edit-resolution-message-template-body"
    Given I fill in "edit-resolution-message-template-body" with "ABC"
    When I click "#edit-resolution-message-template"
    And I wait for "3" seconds
    Then I should see "RESOLUTION MESSAGE TEMPLATE UPDATED."

  @javascript
  Scenario: A user deletes a resolution message template
    Given a user with role "webrep user" exists and is logged in
    And a resolution message template exists
    And the following disputes exist and have entries:
      |id  |
      |5370|
    And I goto "/escalations/webrep/disputes/5370"
    And I click ".mng-resolution-message-templates-button"
    When I click ".delete-resolution-message-template"
    And I click ".confirm"
    And I wait for "3" seconds
    Then I should see "RESOLUTION MESSAGE TEMPLATE DELETED."

  @javascript
  Scenario: A user selects a resolution message template
    Given a user with role "webrep user" exists and is logged in
    And a resolution message template exists
    And the following disputes exist and have entries:
      |id  |
      |5370|
    And I goto "/escalations/webrep/disputes/5370"
    And I click "#show-edit-ticket-status-button"
    And I click "#NEW"
    When I select "Templar" from "select-new-resolution-message-template-status"
    And I wait for "3" seconds
    Then I should see content "This is a test." within ".ticket-status-comment"

  @javascript
  Scenario: A user creates a new resolution message template
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |id  |
      |5370|
    And I goto "/escalations/webrep/disputes/5370"
    And I click ".mng-resolution-message-templates-button"
    And I click "#create-resolution-message-template"
    When I click "#save-resolution-message-template"
    And I wait for "3" seconds
    Then I should see "THERE WAS AN ERROR CREATING THE RESOLUTION MESSAGE TEMPLATE."
    Then I should see "Name can't be blank and Body can't be blank"

  Scenario: A user creates a new named search for disputes
    Given a user with role "webrep user" exists and is logged in
    When I goto "/escalations/webrep/disputes"
    And I trigger-click "#advanced-search-button"
    And I fill in "search_name" with "Lab"
    And I trigger-click "#submit-advanced-search"
    And I trigger-click "#filter-cases"
    Then I should see content "Lab" within "#saved-searches-wrapper"

  @javascript
  Scenario: A user uses a new named search for disputes
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |id|status|
      |1 |NEW   |
    And the following disputes exist and have entries:
      |id|status|
      |2 |NEW   |
    And a named search with the name, "Cucumber" exists
    And a named search criteria exists with field_name: "status" and value: "NEW"
    When I goto "/escalations/webrep/disputes?f=closed"
    Then I should not see "0000000001"
    Then I should not see "NEW"
    Then I should not see "0000000002"
    And I trigger-click "#filter-cases"
    And I trigger-click ".saved-search"
    Then I should see "0000000001"
    Then I should see "NEW"
    Then I should see "0000000002"

  @javascript
  Scenario: A user creates a new named search for disputes
    Given a user with role "webrep user" exists and is logged in
    When I goto "/escalations/webrep/disputes?f=closed"
    And I trigger-click "#advanced-search-button"
    And I fill in "search_name" with "Cucumber"
    And I trigger-click "#submit-advanced-search"
    And I trigger-click "#filter-cases"
    Then I should see content "Cucumber" within "#saved-searches-wrapper"

  @javascript
  Scenario: A user creates a duplicate named search for disputes
    Given a user with role "webrep user" exists and is logged in
    And a named search with the name, "Cucumber" exists
    And a named search criteria exists with field_name: "status" and value: "NEW"
    When I goto "/escalations/webrep/disputes?f=closed"
    And I trigger-click "#advanced-search-button"
    And I fill in "search_name" with "Cucumber"
    And I trigger-click "#submit-advanced-search"
    And I trigger-click "#filter-cases"
    Then I should see content "Cucumber" within "#saved-searches-wrapper"
    And There is only one element of class, "named_search_Cucumber"

  @javascript
  Scenario: A user creates a new named search for disputes and stays on the page (tests to make sure multiple named search criteria are not created)
    Given a user with role "webrep user" exists and is logged in
    When I goto "/escalations/webrep/disputes?f=closed"
    And I trigger-click "#advanced-search-button"
    And I fill in "search_name" with "Cucumber"
    And I trigger-click "#submit-advanced-search"
    And I trigger-click "#filter-cases"
    Then I should see content "Cucumber" within "#saved-searches-wrapper"
    Then I wait for "90" seconds
    Then There is only one element of class, "Cucumber"
    
  Scenario: A user updates a dispute's status (top navigation bar)
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |id  |
      |5370|
    When I goto "/escalations/webrep/disputes/5370"
    And I click "#show-edit-ticket-status-button"
    And I click "#ESCALATED"
    And I click ".primary"
    Then I should see content "Escalated" within "#show-edit-ticket-status-button"
    And I click "#show-edit-ticket-status-button"
    And I click "#RESOLVED_CLOSED"
    And I click ".primary"
    Then I should see content "RESOLVED_CLOSED" within "#show-edit-ticket-status-button"
    And I goto "/escalations/webrep/disputes/5370"
    When I click "#edit-dispute-button"
    And I fill in "dispute-customer-name-input" with "John Smith"
    And I fill in "dispute-customer-email-input" with "jsmith@cisco.com"
    And I select "P5" from "dispute-priority-select"
    And I click "#save-dispute-button"
    And I wait for "5" seconds
    And I click "#top_bar_toggle"
    Then I should see content "John Smith" within "#dispute-customer-name"
    And I should see content "jsmith@cisco.com" within "#dispute-customer-email"
    And Dispute entry should have a status of, "P5"

  @javascript
  Scenario: A user tries add a new dispute entry (ad hoc)
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
      |id  |
      |5370|
    And I goto "/escalations/webrep/disputes/5370"
    Then I click link "Research"
    When I click "#add-entries-button"
    And I fill in "add_dispute_entry" with "cisco.com"
    And I click "#button_add_dispute_entry"
    And I wait for "15" seconds
    Then I should see content "cisco.com" within ".entry-data-content"
    And I should see content "WL-med" within ".entry-data-wlbl"
    And I should see content "BL-heavy" within ".entry-data-wlbl"
