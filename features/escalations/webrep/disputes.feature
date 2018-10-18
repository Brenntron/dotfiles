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
    When I goto "escalations/webrep/tickets?f=open"
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
    When I goto "escalations/webrep/tickets?f=open"
    And I click "#table-show-columns-button"
    And I trigger-click "#case-id-checkbox"
    And I trigger-click "#status-checkbox"
    And I trigger-click "#submitter-type-checkbox"
    And I trigger-click "#submitter-org-checkbox"
    And I trigger-click "#submitter-domain-checkbox"
    And I trigger-click "#contact-name-checkbox"
    And I trigger-click "#contact-email-checkbox"
    When I goto "escalations/webrep/tickets?f=open"
    Then I should not see "CASE ID"
    Then I should not see "STATUS"
    Then I should see "SUBMITTER TYPE"
    Then I should see "SUBMITTER ORG"
    Then I should see "SUBMITTER DOMAIN"
    Then I should see "CONTACT NAME"
    Then I should see "CONTACT EMAIL"
