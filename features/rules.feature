Feature: Rules
  In order to import, create or edit rules
  as a user
  I will provides ways to interact with rules

 # ==== Appending the rule category to the Rule message ===

  @javascript
  Scenario: A new rule can be created and displayed
    Given a user with role "analyst" exists and is logged in
    And I wait for "3" seconds
    Given the following bugs exist:
      |  id  | bugzilla_id | state  | user_id |
      | 2222 |   2222228   | OPEN   |    1    |
    And the following rule categories exist:
      | category  | id |
      | BLACKLIST |  1 |
    When I goto "/bugs/2222"
    And  I click the "Rules" tab
    And  I click button "create"
    And  I click "use standard form"
    And  I select "BLACKLIST" from "rule_category_id"
    And  I fill in "rule[message]" with "Test message"
    And  I fill in "rule[detection]" with "Detection test"
    And  I select "unknown" from "rule[class_type]"
    And  I fill in "summary" with "rule doc summary"
    And  I click "Create Rule"
    And  I wait for "1" seconds
    When I click the "Rules" tab
    And  I click button "list all"
    Then I should see "Test message"
    And  I should see a rule with state "NEW" version "new_rule"
    And I should see "Test message"
    When I check "rule[id]"
    And  I click "edit"
    And  I fill in "rule[rule_content]" with "# alert (msg:"short msg"; flow:established; content:"E_|00 03 05|"; depth:5; metadata:ruleset community; classtype:misc-activity; sid:22211; rev:3;)"
    And  I click button "Save Changes"
    And  I wait for "8" seconds
    Then I should see a rule with state "FAILED" version "new_rule"
    And I should see "short msg"

  @javascript
  Scenario: Rule category drop down should sort by frequency of use
    Given a user with role "analyst" exists and is logged in
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
    Given a user with role "analyst" exists and is logged in
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
    Given a user with role "analyst" exists and is logged in
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
    Given a user with role "analyst" exists and is logged in
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
    Given a user with role "analyst" exists and is logged in
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


  # ==== Existing rule ===

  @javascript
  Scenario: Viewing an exisiting rule
    Given a user with role "analyst" exists and is logged in
    And I wait for "3" seconds
    Given the following bugs exist:
      |  id  | bugzilla_id | state  | user_id |
      | 2222 |   222222    | OPEN   |    1    |
    Given the following rule categories exist:
      | category  | id |
      | BLACKLIST |  1 |
    When the following rules exist:
      | id | gid |  sid  | rev |   state   | publish_status |     message       | rule_category_id |
      | 11 |  1  | 22211 |  3  | UNCHANGED |     SYNCHED    | BLACKLIST message |        1         |
    And bug with id "2222" has rule with id "11"
    When I goto "/bugs/2222"
    And I click the "Rules" tab
    And I click button "list all"
    Then I should see rule "11" state "UNCHANGED" version "1:22211:3"
    And I should see "BLACKLIST message"


  # ==== Editing a rule ===

  @javascript
  Scenario: One or more rules can be selected on a bug to view or edit
    Given a user with role "analyst" exists and is logged in
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

  @javascript
  Scenario: A rule can be edited
    Given a user with role "analyst" exists and is logged in
    And I wait for "3" seconds
    Given the following bugs exist:
      |  id  | bugzilla_id | state  | user_id |
      | 2222 |   222222    | OPEN   |    1    |
    And the following rule categories exist:
      | category  | id |
      | BLACKLIST |  1 |
    And the following rules exist:
      | id | gid |  sid  | rev |   state   | publish_status |     message       | rule_category_id |
      | 11 |  1  | 22211 |  3  | UNCHANGED |     SYNCHED    | BLACKLIST message |        1         |
    And bug with id "2222" has rule with id "11"
    When I goto "/bugs/2222"
    And  I click the "Rules" tab
    And  I click button "list all"
    And  I uncheck "rule_11"
    And  I click "edit"
    Then I should not see div element with class "rule_11"
    When I click the "Rules" tab
    And  I check "rule_11"
    And  I click "edit"
    Then I should see div element with class "rule_11"
    When I fill in "rule[rule_content]" with "# alert tcp $HOME_NET any -> 64.245.58.0/23 any (msg:"short msg"; flow:established; content:"E_|00 03 05|"; depth:5; metadata:ruleset community; classtype:misc-activity; sid:22211; rev:3;)"
    And  I click button "Save Changes"
    And  I wait for "8" seconds
    Then I should see rule "11" state "UPDATED" version "1:22211:3"
    And I should see "short msg"

  @javascript
  Scenario: Valid current edited rule should have CSS class
    Given a user with role "analyst" exists and is logged in
    And I wait for "3" seconds
    Given the following bugs exist:
      |  id  | bugzilla_id | state  | user_id |
      | 2222 |   222222    | OPEN   |    1    |
    And the following rule categories exist:
      | category  | id |
      | BLACKLIST |  1 |
    And the following rules exist:
      | id | gid |  sid  | rev |   state   | publish_status |     message       | rule_category_id |
      | 11 |  1  | 22211 |  3  | UNCHANGED |     SYNCHED    | BLACKLIST message |        1         |
    And bug with id "2222" has rule with id "11"
    When I goto "/bugs/2222"
    And  I click the "Rules" tab
    And  I click button "list all"
    And  I uncheck "rule_11"
    And  I click "edit"
    Then I should not see div element with class "rule_11"
    When I click the "Rules" tab
    And  I check "rule_11"
    And  I click "edit"
    Then I should see div element with class "rule_11"
    When I fill in "rule[rule_content]" with "# alert (msg:"short msg"; flow:established; content:"E_|00 03 05|"; depth:5; metadata:ruleset community; classtype:misc-activity; sid:22211; rev:3;)"
    And  I click button "Save Changes"
    And  I wait for "8" seconds
    Then I should see rule "11" state "FAILED" version "1:22211:3"
    And I should see "short msg"


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


  Scenario: load new rule from grep string model test
    Given rule content
    And grep output for rule content
    When code calls load_rule_from_grep on rule content
    Then a rule record for rule conent will exist

  Scenario: synch existing rule with same rev in db model test
    Given rule content for following rule:
      | gid | sid | rev | state     |
      |  1  | 101 |  4  | UNCHANGED |
    And grep output for rule content
    And I wait for "3" seconds
    When code calls load_rule_from_grep on rule content
    Then rule record will be unchanged

  Scenario: synch updated rule with earlier rev in db model test
    Given rule content for following rule:
      | id | gid | sid | rev | state     |
      |  7 |  1  | 101 |  4  | UNCHANGED |
    And rule content rev set to "5"
    And grep output for rule content
    And I wait for "3" seconds
    When code calls load_rule_from_grep on rule content
    Then rule record will be updated

  Scenario: do not synch updated rule with earlier rev in db model test
    Given rule content for following rule:
      | id | gid | sid | rev | state     |
      |  7 |  1  | 101 |  4  | UPDATED   |
    And rule content rev set to "5"
    And grep output for rule content
    And I wait for "3" seconds
    When code calls load_rule_from_grep on rule content
    Then rule record will marked out of date

  Scenario: do not synch updated rule with earlier rev in db model test
    Given rule content for following rule:
      | id | gid | sid | rev | state     |
      |  7 |  1  | 101 |  4  | FAILED    |
    And rule content rev set to "5"
    And grep output for rule content
    And I wait for "3" seconds
    When code calls load_rule_from_grep on rule content
    Then rule record will marked out of date





