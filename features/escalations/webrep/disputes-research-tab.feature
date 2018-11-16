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
    When I wait for the ajax request to finish
    Then "#disputes-research-table" should be visible
    And the Entry preload with id "1" should exist

  @javascript
  Scenario: In the Research Tab, all variables and values should be properly calculated and displayed
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |id|
      |1 |
    When I goto "escalations/webrep/disputes/1/"
    Then I click "#research-tab-link"
    Then I should see content "talosintelligence.com" within ".research-table-row-wrapper"
    Then I should see content "WBRS" within ".research-table-row-wrapper"
    Then I should see content "SBRS" within ".research-table-row-wrapper"
    Then I should see content "CATEGORY" within ".research-table-row-wrapper"
    Then I should see content "HOSTNAME" within ".research-table-row-wrapper"
    Then I should see content "STATUS" within ".research-table-row-wrapper"
    Then I should see content "RESOLUTION" within ".research-table-row-wrapper"
    Then I should see content "AS OF" within ".research-table-row-wrapper"
    Then I should see content "WBRS RULE HITS" within ".research-table-row-wrapper"
    Then I should see content "WBRS RULES" within ".research-table-row-wrapper"
    Then I should see content "WL/BL" within ".research-table-row-wrapper"
    Then I should see content "REFERENCED ON" within ".research-table-row-wrapper"
    Then I should see content "SBRS RULE HITS" within ".research-table-row-wrapper"
    Then I should see content "SBRS RULES" within ".research-table-row-wrapper"
    Then I should see content "CROSSLISTED URLS" within ".research-table-row-wrapper"
    Then I should see content "REPTOOL CLASS" within ".research-table-row-wrapper"
    Then I should see content "UMBRELLA" within ".research-table-row-wrapper"
    Then I should see content "LAST SUBMITTED" within ".research-table-row-wrapper"
    Then I should see content "No score." within ".research-table-row-wrapper"
    Then I should see content "Unresolved" within ".research-table-row-wrapper"
    Then I should see content "Unclassified" within ".research-table-row-wrapper"
