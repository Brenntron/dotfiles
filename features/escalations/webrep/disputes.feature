Feature: Disputes
  In order to interact with disputes
  as a user
  I will provide ways to interact with disputes

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
    |3 |vrtincom    |
    And the following disputes exist:
    |id|user_id|
    |2 |3      |
    When I goto "escalations/webrep/disputes"
    And I click ".take-dispute-2"
    Then I see "ASSIGNED" in element "#status_2"
    Then I should see user, "Cucumber", in element "#owner_2"

