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
  Scenario: a user takes a dispute and status is updated to assigned
    Given a user with role "webrep user" exists with cvs_username, "Cucumber", exists and is logged in
    Given the following users exist
    |id|cvs_username|
    |3 |  vrtincom  |
    And the following disputes exist:
    |id|user_id|
    |2 |   3   |
    When I goto "escalations/webrep/disputes"
    And I click ".take-dispute-2"
    Then I see "ASSIGNED" in element "#status_2"
    Then I should see user, "Cucumber", in element "#owner_2"
