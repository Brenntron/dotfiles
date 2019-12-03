Feature: WebRep Reports
  In order to view and export reports
  I will provide a reports interface

  @javascript
  Scenario: a user goes to the Reporting Dashboard page and sees their own tickets
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
    |id|
    |1 |
    And the following dispute_entries exist:
    |status           | resolution | case_resolved_at  |
    |RESOLVED_CLOSED  | FIXED_FP   | 2018-11-06 16:29:5|
    When I goto "escalations/webrep/dashboard"
    Then I should see content "My Tickets" within ".dashboard-header"


  @javascript
  Scenario: a user views their Team Tickets
  Given a user with role "webrep user" exists and is logged in
  And the following disputes exist:
  |id|
  |1 |
  And the following dispute_entries exist:
  |status           | resolution | case_resolved_at  |
  |RESOLVED_CLOSED  | FIXED_FP   | 2018-11-06 16:29:5|
  When I goto "escalations/webrep/dashboard"
  And I click "My Team Tickets"
  Then I should see content "My Team Tickets" within ".dashboard-header"


  @no-js-errors
  Scenario: a user goes to the Resolution Report page and exports a report
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
    |id|
    |1 |
    And the following dispute_entries exist:
    |status           | resolution | case_resolved_at  |
    |RESOLVED_CLOSED  | FIXED_FP   | 2018-11-06 16:29:5|
    When I goto "escalations/webrep/dashboard"
    And I click "#export-reports-dropdown-button"
    Then I click "#export-reports-button"
    Then I should receive a file of type "text/html; charset=utf-8"