Feature: Disputes
  In order to interact with disputes
  as a user
  I will provide ways to interact with disputes

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
    Then I see "Cucumber" in element "#owner_2"

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
  Scenario: when the user encounters a situation in which no results exists (therefore none returned),
            an error modal should display
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
    Then check if dispute id, '1', has a related_id of '2'