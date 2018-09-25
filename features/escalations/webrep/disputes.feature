Feature: Disputes
  In order to interact with disputes
  as a user
  I will provide ways to interact with disputes

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
    Then I should see "RE-OPENED"


