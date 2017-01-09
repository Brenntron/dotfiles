Feature: Rules
  In order to import, create or edit rules
  as a user
  I will provides ways to interact with rules

 # ==== Appending the rule category to the Rule message ===
  @javascript
  Scenario: A new rule can be created with a rule category
    Given a user exists and is logged in
    And the following bugs exist:
      | id      | bugzilla_id | state  | user_id | summary             | product | component   | version | description       |
      |222222   | 222222      | OPEN   | 1       | [BP][NSS] fixed bug | Research| Snort Rules | 2.6.0   | test description3 |
    And the following rule categories exist:
      |category       |
      |BLACKLIST      |
      |FILE-EXECUTABLE|
      |OS-LINUX       |
    Then I wait for "3" seconds
    And  I goto "/bugs/222222"
    And  I should see "222222"
    Then I click the "Rules" tab
    Then I click button "create"
    Then I click "use standard form"
    And  I should see "New Rule"
    And  I select "FILE-EXECUTABLE" from "rule_category_id"
    And  I fill in "rule[message]" with "Test Message"
    And  I fill in "rule[detection]" with "Detection test"
    And  I select "unknown" from "rule[class_type]"
    And  I fill in "summary" with "This is the rule doc summary"
    Then I click "Create Rule"
    And  I wait for "3" seconds
    Then I click the "Rules" tab
    Then I click button "list all"
    And  I should see "FILE-EXECUTABLE Test Message"

  @javascript
  Scenario: Rule category drop down should sort by frequency of use
  Given a user exists and is logged in
    And the following bugs exist:
      | id      | bugzilla_id | state  | user_id | summary             | product | component   | version | description       |
      |222222   | 222222      | OPEN   | 1       | [BP][NSS] fixed bug | Research| Snort Rules | 2.6.0   | test description3 |
    And the following rule categories exist:
      |category       | id |
      |BLACKLIST      |  1 |
      |FILE-EXECUTABLE|  2 |
      |OS-LINUX       |  3 |
    And the following rules exist:
      | message                 | rule_category_id |
      | BLACKLIST message       | 1                |
      | OS-LINUX message        | 3                |
      | OS-LINUX second message | 3                |
    Then I wait for "3" seconds
    And  I goto "/bugs/222222"
    Then I click the "Rules" tab
    Then I click button "create"
    Then I click "use standard form"
    Then "OS-LINUX" should be listed first
    And  I select "BLACKLIST" from "rule_category_id"
    And  I fill in "rule[message]" with "Test Message"
    And  I fill in "rule[detection]" with "Detection test2"
    And  I select "unknown" from "rule[class_type]"
    And  I fill in "summary" with "This is the rule doc summary"
    Then I click "Create Rule"
    And  I wait for "3" seconds
    Then I click the "Rules" tab
    Then I click button "create"
    Then I click "use standard form"
    Then "BLACKLIST" should be listed first




  # ==== Creating a rule ===

  @javascript
  Scenario: A new rule is only created when required fields are filled in
    Given a user exists and is logged in
    And the following bugs exist:
      | id      | bugzilla_id | state  | user_id | summary             | product | component   | version | description       |
      |222222   | 222222      | OPEN   | 1       | [BP][NSS] fixed bug | Research| Snort Rules | 2.6.0   | test description3 |
    And the following rule categories exist:
      |category       | id |
      |BLACKLIST      |  1 |
      |FILE-EXECUTABLE|  2 |
      |OS-LINUX       |  3 |
    Then I wait for "3" seconds
    And  I goto "/bugs/222222"
    Then I click the "Rules" tab
    Then I click button "create"
    Then I click "use standard form"
    And  I select "BLACKLIST" from "rule_category_id"
    Then I click "Create Rule"
    Then I wait for "2" seconds
    Then I should see "Please fill in required fields."
    And  I fill in "rule[message]" with "Test Message the third"
    And  I fill in "rule[detection]" with "Detection test3"
    And  I select "unknown" from "rule[class_type]"
    Then I click "Create Rule"
    Then I wait for "2" seconds
    Then I should see "Please fill in required fields."
    And  I fill in "summary" with "This is the rule doc summary"
    Then I click "Create Rule"
    Then I wait for "1" seconds
    Then I click the "Rules" tab
    Then I click button "list all"
    Then I should see "BLACKLIST Test Message the third"


  @javascript
  Scenario: When a new rule is created, the policy options and toggle should populate checkbox values
    Given a user exists and is logged in
    And the following bugs exist:
      | id      | bugzilla_id | state  | user_id | summary             | product | component   | version | description       |
      |222222   | 222222      | OPEN   | 1       | [BP][NSS] fixed bug | Research| Snort Rules | 2.6.0   | test description3 |
    Then I wait for "3" seconds
    And  I goto "/bugs/222222"
    Then I click the "Rules" tab
    Then I click button "create"
    Then I click "use standard form"
    And  I check "security-ips"
    Then the "security-ips" field should be "policy security-ips drop"
    Then I toggle "bootstrap-switch-container"
    Then the "security-ips" field should be "policy security-ips alert"
    Then I check "max-detect-ips"
    Then  the "max-detect-ips" field should be "policy max-detect-ips drop"
    Then the "security-ips" field should be "policy security-ips alert"

  @javascript
  Scenario: When a new rule is created, the service options should populate correctly
    Given a user exists and is logged in
    And the following bugs exist:
      | id      | bugzilla_id | state  | user_id | summary             | product | component   | version | description       |
      |222222   | 222222      | OPEN   | 1       | [BP][NSS] fixed bug | Research| Snort Rules | 2.6.0   | test description3 |
    And the following rule categories exist:
      |category       | id |
      |BLACKLIST      |  1 |
      |FILE-EXECUTABLE|  2 |
      |OS-LINUX       |  3 |
    Then I wait for "3" seconds
    And  I goto "/bugs/222222"
    Then I click the "Rules" tab
    Then I click button "create"
    Then I click "use standard form"
    And  I click "other"
    Then I click "mysql"
    Then I click "kerberos"
    And  I select "BLACKLIST" from "rule_category_id"
    And  I fill in "rule[message]" with "Test Message the third"
    And  I fill in "rule[detection]" with "Detection test3"
    And  I select "unknown" from "rule[class_type]"
    And  I fill in "summary" with "This is the rule doc summary"
    # dropdown needs to be obscured to find Create Rule button
    Then I hide the element with class "other-dropdown"
    Then I click "Create Rule"
    Then I wait for "1" seconds
    Then I click the "Rules" tab
    Then I click button "list all"
    And  I click "new_rule"
    Then I should see "service mysql"
    Then I should see "service kerberos"
    And  I should not see "telnet"

  @javascript
  Scenario: When a new rule is created, the rule doc impact should populate based on class type selection
    Given a user exists and is logged in
    And the following bugs exist:
      | id      | bugzilla_id | state  | user_id | summary             | product | component   | version | description       |
      |222222   | 222222      | OPEN   | 1       | [BP][NSS] fixed bug | Research| Snort Rules | 2.6.0   | test description3 |
    And the following rule categories exist:
      |category       | id |
      |BLACKLIST      |  1 |
      |FILE-EXECUTABLE|  2 |
      |OS-LINUX       |  3 |
    Then I wait for "3" seconds
    And  I goto "/bugs/222222"
    Then I click the "Rules" tab
    Then I click button "create"
    Then I click "use standard form"
    And  I select "BLACKLIST" from "rule_category_id"
    And  I fill in "rule[message]" with "Test Message the third"
    And  I fill in "rule[detection]" with "Detection test3"
    And  I select "unknown" from "rule[class_type]"
    And  I fill in "summary" with "This is the rule doc summary"
    Then I hide the element with class "other-dropdown"
    Then I click "Create Rule"
    Then I wait for "1" seconds
    Then I click the "Rules" tab
    Then I click button "list all"
    And  I click "new_rule"
    Then I should see "This is the rule doc summary"
    Then I should see "Unknown Traffic"


  @javascript
  Scenario: One or more rules can be selected on a bug to view or edit
    Given a user exists and is logged in
    And the following bugs exist:
      | id      | bugzilla_id | state  | user_id | summary             | product | component   | version | description       |
      |222222   | 222222      | OPEN   | 1       | [BP][NSS] fixed bug | Research| Snort Rules | 2.6.0   | test description3 |
    And "3" rules exist and belong to bug "222222"
    Then I wait for "3" seconds
    And  I goto "/bugs/222222"
    Then I click the "Rules" tab
    And  I check "rule_1"
    And  I check "rule_2"
    Then I click "edit"
    And  I should see div element with class "rule_1"
    And  I should see div element with class "rule_2"
    And  I should not see div element with class "rule_3"
    Then I click "list all"
    And  I uncheck "rule_1"
    Then I click "edit"
    And  I should not see div element with class "rule_1"
    And  I should see div element with class "rule_2"
    Then I click "list all"
    And  I click "view"
    And  I should not see div element with class "rule_1"
    And  I should see div element with class "rule_2"
    Then I click "list all"
    And  I check "rule_3"
    Then I click "view"
    And  I should not see div element with class "rule_1"
    And  I should see div element with class "rule_2"
    And  I should see div element with class "rule_3"


    # ==== Editing rule docs ===
# TODO: Fix test: textarea value is not being set correctly within test
#  @javascript @now
#  Scenario: a user can edit rule docs for a new rule
#    Given a user exists and is logged in
#    And the following bugs exist:
#      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
#      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
#    Then I wait for "3" seconds
#    And I goto "/bugs/222222"
#    And I click ".rules-tab"
#    And I click button "create"
#    And  I fill in "rule[rule_content]" with "1: connection:alert tcp $EXTERNAL_NET  ->  $HOME_NET any (msg:"select a category ";flow:to_client,established;detection:;metadata: balanced-ips, security-ips, drop, ftp-data, http, imap, pop3, , ;reference:cve,2006-5745; reference:cve,2568-5014; classtype:attempted-user)"
#    Then I fill in "summary" with "This is the summary"
#    Then I click button "Create Rule"
#    Then I click the "Rules" tab
#    Then I click button "list all"
#    Then I check "rule_1"
#    Then I click "edit"
#    Then I do some debugging
#    And I fill in "details" with "these are the details"
#    And I fill in "summary" with "This is edited content"
#    Then show me the page
#    Then take a photo
#    Then I click "Save Changes"
#    Then take a photo
#    And I wait for "2" seconds
#    Then I click "new_rule"
#    And I should see "This is edited content"
#    And I should see "these are the details"
#    And I should see "Attempted User Privilege Gain"
#    And I should not see "This is the summary"









