Feature: Bug
  In order to import, create or edit bugs
  as a user
  I will provides ways to interact with bugs


  @javascript
  Scenario: A user can view and filter bugs
    Given a user exists and is logged in
    And the following bugs exist:
      | bugzilla_id | state | user_id | summary                                     | product  | component   | version | description       |
      | 111111      | OPEN  | 1       | [[TELUS][VULN][BP] [SID] 22078 test summary | Research | Snort Rules | 2.6.0   | test description  |
      | 222222      | OPEN  | 2       | No Tags in this one                         | Research | Snort Rules | 2.6.0   | test description2 |
      | 222222      | FIXED | 2       | [BP][NSS] fixed bug                         | Research | Snort Rules | 2.6.0   | test description3 |
    Then I wait for "3" seconds
    And  I goto "/bugs"
    And  I should see "Bugs"
    And  I goto "/bugs?q=open-bugs"
    Then I should see "test summary"
    And  I should not see "fixed bug"
    And  I goto "/bugs?q=my-bugs"
    Then I should see "[[TELUS][VULN][BP] [SID] 22078 test summary"
    And  I should not see "No Tags in this one"
    Then I goto "/bugs?q=fixed-bugs"
    And  I should see "[BP][NSS] fixed bug"
    And  I should not see "No Tags in this one"


# ==== Creating a Bug with Tags ===
  @javascript
  Scenario: A new bug can be created with tags
    Given a user exists and is logged in
    And the following tags exist:
      | name  |
      | TELUS |
      | VULN  |
      | BP    |
    Then I wait for "3" seconds
    And  I goto "/bugs/new"
    And  I select "2.5.2" from "bug_version"
    And  I fill in "bug_summary" with "New Bug Summary"
    And  I fill in "bug_description" with "This is my description."
    And  I fill in selectized with "TELUS"
    Then show me the page
    Then I wait for "15" seconds
    Then I click "Create Bug"
    Then I should see "[TELUS]New Bug Summary"
    And  the selectize field contains the text "TELUS"



  # ==== Editing Tags ===
  @javascript
  Scenario: The summary text should update with tag edits
    Given a user exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
    Then I wait for "3" seconds
    And I goto "/bugs/222222"
    Then I should see "[BP][NSS] fixed bug"
    And  I fill in selectized with "TELUS"
    Then the selectize field contains the text "TELUS"
    And I should see "[TELUS] fixed bug"
    Then I fill in selectized with "BP"
    Then the selectize field contains the text "TELUSBP"
    Then I should see "[TELUS][BP] fixed bug"
    And I should not see "[BP][NSS] fixed bug"

  @javascript
  Scenario: A bug can be imported

  @javascript
  Scenario: a user can return to the index from viewing a bug

  @javascript
  Scenario: a user can change the state of a bug

  @javascript
  Scenario: a user can not set the state of a bug to pending when exploits are missing attachments

  @javascript
  Scenario: a user can change the editor of a bug

  @javascript
  Scenario: a user can change the committer of a bug

  @javascript
  Scenario: a user can add a reference to a bug

  @javascript
  Scenario: a user can add a new rule to a bug

  @javascript
  Scenario: a user can import an existing rule to a bug

  @javascript
  Scenario: a user can remove a rule from a bug

  @javascript
  Scenario: a user can edit a rule attached to a bug

  @javascript
  Scenario: a user can test a rule

  @javascript
  Scenario: a user can test an attachment

  @javascript
  Scenario: a user can edit a rule attached to a bug

  @javascript
  Scenario: a user can edit research notes

  @javascript
  Scenario: a user can edit committer notes.

  @javascript
  Scenario: a user can add a comment

  @javascript
  Scenario: a user can sort history from oldest to newest messages.

  @javascript
  Scenario: a user can view a bug in bugzilla