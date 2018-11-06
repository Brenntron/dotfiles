Feature: WebRep Reports
  In order to view and export reports
  I will provide a reports interface

  @javascript
  Scenario: a user goes to the Resolution Report page
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
    |id|
    |1 |
    And the following dispute_entries exist:
    |status           | resolution | case_resolved_at  |
    |RESOLVED_CLOSED  | FIXED_FP   | 2018-11-06 16:29:5|
    When I goto "escalations/webrep/dashboard"
    And I fill in "report[date_from]" with "2018-01-01"
    And I fill in "report[date_to]" with "2018-12-31"
    And I click ".create-report" and switch to the new window
    Then I wait for "3" seconds
    Then I should see "Resolution Report"
    Then I should see content "DATE" within ".content-wrapper"
    Then I should see content "RESOLUTION" within ".content-wrapper"
    Then I should see content "%" within ".content-wrapper"
    Then I should see content "COUNT" within ".content-wrapper"
    Then I should see content "100" within ".content-wrapper"

  @javascript
  Scenario: a user goes to the Resolution Report page and exports a per-resolution report
  Given a user with role "webrep user" exists and is logged in
  And the following disputes exist:
  |id|
  |1 |
  And the following dispute_entries exist:
  |status           | resolution | case_resolved_at  |
  |RESOLVED_CLOSED  | FIXED_FP   | 2018-11-06 16:29:5|
  When I goto "escalations/webrep/dashboard"
    And I fill in "report[date_from]" with "2018-01-01"
    And I fill in "report[date_to]" with "2018-12-31"
  And I click ".create-report" and switch to the new window
  Then I trigger-click ".per-resolution-export"
  Then I wait for "3" seconds
  Then I should receive a file of type "application/octet-stream"

  @javascript
  Scenario: a user goes to the Resolution Report page and exports a per-engineer report
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
    |id|
    |1 |
    And the following dispute_entries exist:
    |status           | resolution | case_resolved_at  |
    |RESOLVED_CLOSED  | FIXED_FP   | 2018-11-06 16:29:5|
    When I goto "escalations/webrep/dashboard"
    And I fill in "report[date_from]" with "2018-01-01"
    And I fill in "report[date_to]" with "2018-12-31"
    And I click ".create-report" and switch to the new window
    Then I trigger-click ".per-engineer-export"
    Then I wait for "3" seconds
    Then I should receive a file of type "application/octet-stream"

  @javascript
  Scenario: a user goes to the Resolution Report page and exports a per-customer report
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
    |id|
    |1 |
    And the following dispute_entries exist:
    |status           | resolution | case_resolved_at  |
    |RESOLVED_CLOSED  | FIXED_FP   | 2018-11-06 16:29:5|
    When I goto "escalations/webrep/dashboard"
    And I fill in "report[date_from]" with "2018-01-01"
    And I fill in "report[date_to]" with "2018-12-31"
    And I click ".create-report" and switch to the new window
    Then I trigger-click ".per-customer-export"
    Then I wait for "3" seconds
    Then I should receive a file of type "application/octet-stream"

  @javascript
  Scenario: a user goes to the Resolution Age Report page and exports a Resolution Age Report
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
    |id|
    |1 |
    And the following dispute_entries exist:
    |status           | resolution | case_resolved_at  |
    |RESOLVED_CLOSED  | FIXED_FP   | 2018-11-06 16:29:5|
    When I goto "/escalations/webrep/disputes/resolution_age_report?customer_id=1&date_from=2018-01-01&date_to=2018-12-30"
    Then take a screenshot
    Then I should see "Resolution Age Report"
    Then I should see "Number of resolved complaints per resolution"
    Then I trigger-click ".resolution-age-export"
    Then I wait for "3" seconds
    Then I should receive a file of type "application/octet-stream"