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


  # ==== Deleteing Bugs ===
  @javascript
  Scenario: A bug can be deleted
    Given a user exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
    Then I wait for "3" seconds
    And I goto "/bugs"
    Then I should see "[BP][NSS] fixed bug"
    And I wait for "1" seconds
    When I click "delete_bug222222"
    And I wait for "1" seconds
    Then I should not see "[BP][NSS] fixed bug"


  # ==== Importing a Bug ===
  @javascript
  Scenario: A bug can be imported
#    Given a user exists and is logged in
#    Then I wait for "3" seconds
#    And I goto "/bugs"
#    And I fill in "import_bug" with "145359"
#    And take a photo
#    And I do some debugging
#    And I click "button_import"  <- this is broken
#    And take a photo
#    Then I wait for "40" seconds
#    And  I goto "/bugs"
#    Then I should see "[SID] 2330 This is a fake bug"
#    And I should see "145359"  <- this is broken

  @javascript
  Scenario: a user can not set the state of a bug to pending when exploits are missing attachments
    Given a user exists and is logged in
    And the following exploit types exist:
      | id | name   | description                              |
      | 1  | core   | Core Impact exploit module.              |
      | 2  | telus  | Other publicly available exploit module. |
      | 3  | canvas | Immunity Canvas exploit module.          |
    And the following reference types exist:
      | id | name    | description  | example |
      | 1  | cve     | just a thing | 222-222 |
      | 2  | url     | just a thing | 222-222 |
      | 3  | bugtraq | just a thing | 222-222 |
    And the following references exist:
      | id | reference_data | reference_type_id | bug_id |
      | 1  | 2006-5745      | 1                 | 222222 |
    And the following exploits exist:
      | id | data                                                                                        | exploit_type_id |
      | 1  | exploits/ms06_071/ms06_071.py - http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2006-5745 | 1               |
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
    And reference with id "1" has exploit with id "1"
    Then I wait for "2" seconds
    And I goto "/bugs/222222"
    And I click "change_state"
    Then I should see "Cant set to pending."
    And I can not select "PENDING" from "state"

  @javascript
  Scenario: a user can return to the index from viewing a bug
    Given a user exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
    Then I wait for "3" seconds
    And I goto "/bugs/222222"
    And I click "back_btn"
    Then I should see "Summary"
    And I should not see "Overview"

  @javascript
  Scenario: a user can change the state of a bug
#    Given a user exists and is logged in
#    And the following bugs exist:
#      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
#      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
#    Then I wait for "3" seconds
#    And I goto "/bugs/222222"
#    And I click "change_state"
#    And I select "PENDING" from "state"
#    And I do some debugging
#    When I click "submit_change"
##    And I change the "state" of bug number "222222" to "PENDING"
#    And I wait for "3" seconds
#    Then I do some debugging
##    And I goto "/bugs/222222"
#    Then I should see "PENDING"
#    And I should not see "Submit State"


  @javascript
  Scenario: a user can change the editor of a bug

  @javascript
  Scenario: a user can change the committer of a bug


  @javascript
  Scenario: a user can add a new rule to a bug
    Given a user exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
    Then I wait for "3" seconds
    And I goto "/bugs/222222"
    And I click ".rules-tab"
    And I click button "create"
    And  I fill in "rule[rule_content]" with "1: connection:alert tcp $EXTERNAL_NET  ->  $HOME_NET any (msg:"select a category ";flow:to_client,established;detection:;metadata: balanced-ips, security-ips, drop, ftp-data, http, imap, pop3, , ;reference:cve,2006-5745; reference:cve,2568-5014; classtype:attempted-user; sid:12345; rev:3)"
    When I click button "Create Rule"
    Then I click ".rules-tab"
    And I should see "new_rule"
    And I should see "select a category"


  @javascript
  Scenario: a user can import an existing rule to a bug
#    Given a user exists and is logged in
#    And the following bugs exist:
#      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
#      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
#    Then I wait for "3" seconds
#    And I goto "/bugs/222222"
#    And I click ".rules-tab"
#    And  I fill in "sid" with "24397" <- this next step is broken



  @javascript
  Scenario: a user can remove a rule from a bug
    Given a user exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
    And a rule exists and belongs to bug "222222"
    Then I wait for "3" seconds
    And I goto "/bugs/222222"
    And I click ".rules-tab"

  @javascript
  Scenario: a user can edit a rule attached to a bug
    Given a user exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
    And a rule exists and belongs to bug "222222"
    Then I wait for "3" seconds
    And I goto "/bugs/222222"
    And I click ".rules-tab"
    And I toggle checkbox ".rule_1"
    And I click button "edit"
    And  I fill in "rule[rule_content]" with "connection:drop ip $DNS_SERVERS $ORACLE_PORTS -> $SMTP_SERVERS $HOME_NET any (msg:'BROWSER-IE You deserve this if you use Firefox';flow:to_client,established;detection:So many detections;metadata: balanced-ips, security-ips, drop, ftp-data, http, imap, pop3, red, community;reference:bugtraq,122344; classtype:attempted-user; sid:12345; rev:3)"
    And I do some debugging
    When I click button "Save Changes"
    Then I click ".rules-tab"


  @javascript
  Scenario: a user can test a rule
    Given a user exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
    And the following rules exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
    Then I wait for "3" seconds
    And I goto "/bugs/222222"
    And I click ".rules-tab"


  @javascript
  Scenario: a user can test add an attachment

  @javascript
  Scenario: a user can test an attachment

  @javascript
  Scenario: a user can edit research notes
    Given a user exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
    Then I wait for "3" seconds
    And I goto "/bugs/222222"
    And I click ".attachments-tab"

  @javascript
  Scenario: a user can edit committer notes.
    Given a user exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
    Then I wait for "3" seconds
    And I goto "/bugs/222222"
    And I click ".notes-tab"

  @javascript
  Scenario: a user can add a comment
    Given a user exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
    Then I wait for "3" seconds
    And I goto "/bugs/222222"
    And I click ".notes-tab"

  @javascript
  Scenario: a user can sort history from oldest to newest messages.
    Given a user exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
    Then I wait for "3" seconds
    And I goto "/bugs/222222"
    And I click ".history-tab"
