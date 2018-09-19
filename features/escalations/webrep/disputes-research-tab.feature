Feature: Disputes index, Research tab
  In order to interact with disputes' entries as a user, I will provide ways to interact with entires in the Research tab

  @javascript
  Scenario: Disputes with no entries shouldn't attempt to display any entries in the table
    Given a user with role "webrep user" exists with cvs_username, "Cucumber", exists and is logged in
    Given the following users exist
    |id|cvs_username|
    |3 |vrtincom    |
    And the following disputes exist:
    |id|user_id|
    |2 |3      |
    When I goto "escalations/webrep/disputes/2"
    And I click "#research-tab-link"
    Then ".expandable-row-column" should not be visible

  @javascript
  Scenario: Dispute entries with preloaded data display correctly
    Given a user with role "webrep user" exists with cvs_username, "Cucumber", exists and is logged in
    Given the following users exist
    |id|cvs_username|
    |3 |vrtincom    |
    And the following disputes exist and have entries:
    |id|user_id|
    |2 |3      |
    When I goto "escalations/webrep/disputes/2"
    And I click "#research-tab-link"
    Then "#disputes-research-table" should be visible
    
  @javascript
  Scenario: Dispute entries with no preloaded data attempt to fire the preloader
    Given a user with role "webrep user" exists with cvs_username, "Cucumber", exists and is logged in
    Given the following users exist
    |id|cvs_username|
    |3 |vrtincom    |
    And the following disputes exist and have entries without preloads:
    |id|user_id|
    |2 |3      |
    When I goto "escalations/webrep/disputes/2"
    And I click "#research-tab-link"
    Then "#disputes-research-table" should be visible
    And the Entry preload with id "1" should exist

