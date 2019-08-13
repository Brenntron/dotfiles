Feature: RuleHit Resolution Mailer Templates
  In order to interact with RuleHit Resolution Mailer Templates as a user, I will provide ways to interact with them
  
  @javascript
  Scenario: A user should see links as WBRS/SBRS rule hits which creates an email with a RuleHit Resolution Mailer Template
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
    |id|
    |1 |
    And the following dispute_entries exist:
    |ip_address  | dispute_id|uri|
    |2.133.94.166| 1         |   |
    And a Dispute RuleHit exists with name, "sqdk", and RuleType of "WBRS"
    And a Dispute RuleHit exists with name, "Cbl", and RuleType of "SBRS"
    And a RuleHit Resolution Mailer template exists with mnemonic, "sqdk", and body of "Temple Gates"
    And a RuleHit Resolution Mailer template exists with mnemonic, "Cbl", and body of "Wisdom"
    When I goto "escalations/webrep/disputes/1/"
    Then I click "#research-tab-link"
    Then I click "#expand-all-rows"
    Then I click link "inline-wbrs-hit-1"
    Then I should see content "Temple Gates" within ".new-body"
    Then I click ".ui-dialog-titlebar-close"
    Then I click "#research-tab-link"
    Then I click "#expand-all-rows"
    Then I click link "inline-sbrs-hit-2"
    Then I should see content "Wisdom" within ".new-body"

  @javascript
  Scenario: A user creates a new RuleHit Resolution Mailer Template
    Given a user with role "webrep user" exists and is logged in
    When I goto "/escalations/rulehit_resolution_mailer_templates/new"
    Then I fill in "rulehit_resolution_mailer_template[mnemonic]" with "sqdk"
    Then I fill in "rulehit_resolution_mailer_template[to]" with "cisco@cisco.com"
    Then I fill in "rulehit_resolution_mailer_template[cc]" with "cisco@cisco.com"
    Then I fill in "rulehit_resolution_mailer_template[subject]" with "Cucumber"
    Then I fill in "rulehit_resolution_mailer_template[body]" with "This is a test."
    Then I click button "Create Rulehit resolution mailer template"
    Then I should see "Rulehit resolution mailer template was successfully created."

  @javascript
  Scenario: A user updates RuleHit Resolution Mailer Template
    Given a user with role "webrep user" exists and is logged in
    And a RuleHit Resolution Mailer template exists with mnemonic, "sqdk", and body of "Temple Gates"
    When I goto "/escalations/rulehit_resolution_mailer_templates/1/edit"
    And I fill in "rulehit_resolution_mailer_template[mnemonic]" with "sqdk"
    And I fill in "rulehit_resolution_mailer_template[to]" with "jobs@cisco.com"
    And I fill in "rulehit_resolution_mailer_template[cc]" with "hr@cisco.com"
    And I fill in "rulehit_resolution_mailer_template[subject]" with "Capybara"
    And I fill in "rulehit_resolution_mailer_template[body]" with "Run the test."
    And I click button "Update Rulehit resolution mailer template"
    Then I should see "Rulehit resolution mailer template was successfully updated."

  @javascript
  Scenario: A user deletes RuleHit Resolution Mailer Template
    Given a user with role "webrep user" exists and is logged in
    And a RuleHit Resolution Mailer template exists with mnemonic, "sqdk", and body of "Temple Gates"
    When I goto "/escalations/rulehit_resolution_mailer_templates/"
    And I click through "#delete-1" and accept confirmation
    Then I should see "Rulehit resolution mailer template was successfully destroyed."

  @javascript
  Scenario: A user creates an ad hoc email using a RuleHit Resolution Mailer Template
    Given a user with role "webrep user" exists and is logged in
    And a RuleHit Resolution Mailer template exists with mnemonic, "blh", and body of "Temple Gates"
    When I go to "/escalations/webrep/research"
    And I fill in "search_uri" with "cisco.com"
    And I click "submit-button"
    And I wait for "30" seconds
    And I click first element of class ".adhoc-email-trigger"
    Then I should see "Compose New Email"
    Then I should see content "cisco@gmail.com" within ".new-receiver"
    Then I should see content "cisco@gmail.com" within ".cc-email"
    Then I should see content "Cucumber" within "#subject"
    Then I should see content "This is a test body" within ".new-body"