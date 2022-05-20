Feature: Disputes index, Research tab
  In order to interact with disputes' entries as a user, I will provide ways to interact with entries in the Research tab

  @javascript
  Scenario: Disputes with no attachments shouldn't attempt to display any attachments
    Given a user with role "webrep user" exists with cvs_username, "Cucumber", exists and is logged in
    Given the following users exist
    |id|cvs_username|
    |3 |vrtincom    |
    And the following SDR disputes exist:
    |id|user_id|
    |2 |3      |
    When I goto "escalations/sdr/disputes/2"
    And I click "#research-tab-link"
    Then ".expand-data-row-inline" should not be visible

  @javascript
  Scenario: a user wants to verify threat level appear on page load on show page > research tab
    Given a user with role "webrep user" exists and is logged in
    And the following SDR disputes exist:
      | sender_domain_entry |
      | 1234computer.com    |
    When I goto "escalations/sdr/disputes/1"
    Then I click "#research-tab-link"
    And  I wait for "5" seconds
    Then I should see "THREAT LEVEL"
    Then I should see "Untrusted"

  @javascript
  Scenario: SDR Disputes with research data should display correctly
    Given a user with role "webrep user" exists with cvs_username, "Cucumber", exists and is logged in
    Given the following users exist
    |id|cvs_username|
    |3 |vrtincom    |
    And the following SDR disputes exist:
    |id|user_id|
    |2 |3      |
    When I goto "escalations/sdr/disputes/2"
    And I click "#research-tab-link"
    And  I wait for "5" seconds
    Then ".sdr-research-data-present" should be visible

  @javascript
  Scenario: SDR Disputes show the preloader
    Given a user with role "webrep user" exists with cvs_username, "Cucumber", exists and is logged in
    Given the following users exist
    |id|cvs_username|
    |3 |vrtincom    |
    And the following SDR disputes exist:
    |id|user_id|
    |2 |3      |
    When I goto "escalations/sdr/disputes/2"
    And I click "#research-tab-link"
    Then "#sdr-research-loader" should be visible

  @javascript
  Scenario: In the Research Tab, all variables and values should be properly calculated and displayed
    Given a user with role "webrep user" exists and is logged in
    And the following SDR disputes exist:
      |id| sender_domain_entry |
      |1 | cisco.com           |
    When I goto "escalations/sdr/disputes/1/"
    Then I click "#research-tab-link"
    Then I wait for "5" seconds
    Then I should see content "cisco.com" within "#sdr-reputation-data-table"
    Then I should see content "72.163.4.161" within "#sdr-reputation-data-table"
    Then I should see content "9.3" within "#sdr-reputation-data-table"
    Then I should see content "false negative" within ".sdr-dispute-info-wrapper"
    Then I should see content "cisco.com" within ".sdr-dispute-info-wrapper"

  #Send to Corpus

  @javascript
  Scenario: A user can submit all the SDR Dispute Attachments to Corpus
    Given a user with role "webrep user" exists and is logged in
    And the following SDR disputes exist:
      | id | sender_domain_entry |
      | 1  | cisco.com           |
    When I goto "escalations/sdr/disputes/1"
    Then I click "#research-tab-link"
    Then I click ".sdr-corpus-button"
    Then I click "input[name='category0'][value='phish']"
    Then I fill in element, "input[name='subject line0']" with "Test Subject"
    Then I click "input[name='bulk0']"
    Then I click "input[name='virus0']"
