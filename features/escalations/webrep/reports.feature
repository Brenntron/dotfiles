Feature: WebRep Reports
  In order to view and export reports
  I will provide a reports interface

  @javascript
  Scenario: a user goes to the Resolution Report page
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |id| status          | resolution |
      |1 | RESOLVED_CLOSED | UNCHANGED  |
    And a dispute entry with trait "resolved" exists
    When I goto "escalations/webrep/dashboard"
    And I fill in "report[date_from]" with today's date"
    And I fill in "report[date_to]" with today's date"
    And I click ".create-report" and switch to the new window
    Then I wait for "3" seconds
    Then I should see "Resolution Report"
    Then I should see content "DATE" within ".content-wrapper"
    Then I should see content "RESOLUTION" within ".content-wrapper"
    Then I should see content "%" within ".content-wrapper"
    Then I should see content "COUNT" within ".content-wrapper"

  @javascript
  Scenario: a user goes to the Resolution Report page and exports a per-resolution report
  Given a user with role "webrep user" exists and is logged in
  And the following disputes exist and have entries:
  |id| status          | resolution |
  |1 | RESOLVED_CLOSED | UNCHANGED  |
  And a dispute entry with trait "resolved" exists
  When I goto "escalations/webrep/dashboard"
  And I fill in "report[date_from]" with today's date"
  And I fill in "report[date_to]" with today's date"
  And I click ".create-report" and switch to the new window
  Then I trigger-click ".per-resolution-export"
  Then I wait for "3" seconds
  Then I should receive a file of type "application/octet-stream"

  @javascript
  Scenario: a user goes to the Resolution Report page and exports a per-engineer report
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |id|
      |1 |
    When I goto "escalations/webrep/dashboard"
    And I fill in "report[date_from]" with today's date"
    And I fill in "report[date_to]" with today's date"
    And I click ".create-report" and switch to the new window
    Then I trigger-click ".per-engineer-export"
    Then I wait for "3" seconds
    Then I should receive a file of type "application/octet-stream"

  @javascript
  Scenario: a user goes to the Resolution Report page and exports a per-customer report
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |id| status          | resolution |
      |1 | RESOLVED_CLOSED | UNCHANGED  |
    When I goto "escalations/webrep/dashboard"
    And I fill in "report[date_from]" with today's date"
    And I fill in "report[date_to]" with today's date"
    And I click ".create-report" and switch to the new window
    Then I trigger-click ".per-customer-export"
    Then I wait for "3" seconds
    Then I should receive a file of type "application/octet-stream"

  @javascript
  Scenario: a user goes to the Resolution Age Report page and exports a Resolution Age Report
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |id| status          | resolution |
      |1 | RESOLVED_CLOSED | UNCHANGED  |
    When I goto "/escalations/webrep/disputes/resolution_age_report?customer_id=1&date_from=2018-09-01&date_to=2018-09-30"
    Then I should see "Resolution Age Report"
    Then I should see "Number of resolved complaints per resolution"
    Then I trigger-click ".resolution-age-export"
    Then I wait for "3" seconds
    Then I should receive a file of type "application/octet-stream"