Feature: Disputes index, Research tab
  In order to interact with disputes' attachments and research data as a user, I will provide ways to interact with the attachments and research data in the Research tab

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
    Given a user with role "webrep user" exists with cvs_username, "Cucumber", exists and is logged in
    And the following SDR disputes exist:
      | id | sender_domain_entry |
      | 1  | cisco.com           |
    And the following SDR dispute attachments exist:
      | file_name |
      | Test      |
    When I goto "escalations/sdr/disputes/1"
    Then I click "#research-tab-link"
    Then I click "input[name='all attachments']"
    Then I click ".sdr-corpus-button"
    Then I click "input[name='email-category-1'][value='not ads']"
    Then I fill in element, "input[name='subject-1']" with "Test Subject"
    Then I click checkbox with name "tag-bulk-1"
    Then button with id "submitCorpus" should be enabled
    Then I click "#submitCorpus"
    Then I wait for "2" seconds
    Then I should see content "Submitting data to Corpus..." within ".inline-row-loader"

  @javascript
  Scenario: A user cannot submit SDR Dispute Attachments to Corpus if none are selected and lack a category
    Given a user with role "webrep user" exists and is logged in
    And the following SDR disputes exist:
      | id | sender_domain_entry |
      | 1  | cisco.com           |
    And the following SDR dispute attachments exist:
      | file_name |
      | Test      |
    When I goto "escalations/sdr/disputes/1"
    Then I click "#research-tab-link"
    Then I click ".sdr-corpus-button"
    Then I should not see "Send Email Attachments to Corpus"

  @javascript
  Scenario: A user can add multiple tags to corpus submissions
    Given a user with role "webrep user" exists and is logged in
    And the following SDR disputes exist:
      | id | sender_domain_entry |
      | 1  | cisco.com           |
    And the following SDR dispute attachments exist:
      | file_name |
      | Test      |
    When I goto "escalations/sdr/disputes/1"
    Then I click "#research-tab-link"
    Then I click "input[data-id='1']"
    Then I click ".sdr-corpus-button"
    Then I click checkbox with name "tag-bulk-1"
    Then I click checkbox with name "tag-virus-1"
