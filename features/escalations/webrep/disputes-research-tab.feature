Feature: Disputes index, Research tab
  In order to interact with disputes' entries as a user, I will provide ways to interact with entries in the Research tab

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
  Scenario: a user wants to verify threat categories appear on page load on show page > research tab
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
      |id|
      |1 |
    And the following dispute_entries exist:
      |dispute_id   |uri                |entry_type |
      |1            |1234computer.com   |URI/DOMAIN |
    When I goto "escalations/webrep/disputes/1"
    And  I wait for "5" seconds
    Then I click "#research-tab-link"
    Then I should see "Malware Sites"

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
    And take a screenshot
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
    Then I should see content "No score" within ".research-table-row-wrapper"
    Then I should see content "Unresolved" within ".research-table-row-wrapper"
    Then I should see content "Unclassified" within ".research-table-row-wrapper"



# Querying URI + IP (+ IP)
  @javascript
  Scenario: a user wants to add a single resolved host IP to a dispute entry
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
      |id|
      |1 |
    And the following dispute_entries exist:
      |dispute_id   |uri                |entry_type |
      |1            |1234computer.com   |URI/DOMAIN |
    When I goto "escalations/webrep/disputes/1"
    And  I wait for "5" seconds
    Then I click "#research-tab-link"
    And  I should see element ".add-ip-button"
    Then I click ".add-ip-button"
    And  I fill in element, ".add-ip-input" with "1.1.1.1"
    And  I click "Submit Query"
    And  take a screenshot
    Then I wait for "15" seconds
    Then I should see content "1.1.1.1" within ".entry-resolved-ip-content"


  @javascript
  Scenario: a user wants to add multiple resolved host IPs to a dispute entry
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
      |id|
      |1 |
    And the following dispute_entries exist:
      |dispute_id   |uri                |entry_type |
      |1            |1234computer.com   |URI/DOMAIN |
    When I goto "escalations/webrep/disputes/1"
    And  I wait for "5" seconds
    Then I click "#research-tab-link"
    And  I should see element ".add-ip-button"
    Then I click ".add-ip-button"
    And  I fill in element, ".add-ip-input" with "1.1.1.1, 2.2.2.2"
    And  I click "Submit Query"
    Then I wait for "15" seconds
    Then I should see content "1.1.1.1, 2.2.2.2" within ".entry-resolved-ip-content"


  @javascript
  Scenario: a user tries to add an improper IP address as a resolved host IP to a dispute entry
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
      |id|
      |1 |
    And the following dispute_entries exist:
      |dispute_id   |uri            |entry_type |
      |1            |1234computer.com   |URI/DOMAIN |
    When I goto "escalations/webrep/disputes/1"
    And  I wait for "5" seconds
    Then I click "#research-tab-link"
    Then I click ".add-ip-button"
    And  I fill in element, ".add-ip-input" with "drumf"
    And  I click "Submit Query"
    Then I wait for "15" seconds
    And  I should not see content "drumf" within ".entry-resolved-ip-content"


  @javascript
  Scenario: a user wants to view a dispute entry that has a resolved host IP added previously
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
      |id|
      |1 |
    And the following dispute_entries exist:
      |dispute_id   |uri                |entry_type |web_ips     |
      |1            |1234computer.com   |URI/DOMAIN |["1.1.1.1"] |
    When I goto "escalations/webrep/disputes/1"
    And  I wait for "5" seconds
    Then I click "#research-tab-link"
    And  I should see content "1.1.1.1" within ".entry-resolved-ip-content"


  @javascript
  Scenario: a user wants to edit and submit a new resolved host IP on a dispute entry
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
      |id|
      |1 |
    And the following dispute_entries exist:
      |dispute_id   |uri                |entry_type |web_ips     |
      |1            |1234computer.com   |URI/DOMAIN |["1.1.1.1"] |
    When I goto "escalations/webrep/disputes/1"
    And  I wait for "5" seconds
    Then I click "#research-tab-link"
    And  I should see content "1.1.1.1" within ".entry-resolved-ip-content"
    Then I click "Edit IP Addresses"
    And  I fill in element, ".table-ip-input" with "2.2.2.2"
    And  I click "Save IP Addresses"
    And  I wait for "5" seconds
    And  I should see content "2.2.2.2" within ".entry-resolved-ip-content"
    And  take a screenshot


  @javascript
  Scenario: a user cannot add a resolved host IP to a dispute entry that is an IP entry
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
      |id|
      |5 |
    And the following dispute_entries exist:
      | id | dispute_id |ip_address   | uri |
      | 1  | 5          |123.63.22.24 |     |
    When I goto "escalations/webrep/disputes/5"
    And  I wait for "5" seconds
    Then I click "#research-tab-link"
    And  take a screenshot
    And  I should not see element with class "add-ip-button"


  @javascript
  Scenario: A user views the platform information for a dispute entry
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
      | id |
      | 5  |
    # need pending column added for test env?
    Then pending
    And the following dispute_entries exist:
      | id | dispute_id | uri                | entry_type | platform      |
      | 1  | 5          | 1234computer.com   | URI/DOMAIN | TestPlatform  |
    And I go to "escalations/webrep/disputes/5"
    And I wait for "1" seconds
    And I click ".close"
    And I click "#research-tab-link"
    And I wait for "1" seconds
    Then I should see "Research Data"
    Then I should see "TestPlatform"
