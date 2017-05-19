Feature: Rules
  In order to import, create or edit rules
  as a user
  I will provides ways to interact with rules

    ### Rules tab navigation ###

  @javascript
  Scenario: Selecting a rule to view from the table should
  'check' the selected rule and 'uncheck' all others

    Given a user with role "committer" exists and is logged in
    Given the following bugs exist:
      |  id  | bugzilla_id | state  | user_id |
      | 2222 |   222222    | OPEN   |    1    |
    Given the following rule categories exist:
      | category  | id |
      | BLACKLIST |  1 |
    When the following rules exist:
      | id | gid |  sid  | rev |   state   |edit_status| publish_status |     message       | rule_category_id |
      | 13 |  1  | 22212 |  3  | UNCHANGED |  SYNCHED  |     SYNCHED    | BLACKLIST message |        1         |
      | 14 |  1  | 22213 |  3  | UNCHANGED |  SYNCHED  |     SYNCHED    | BLACKLIST message |        1         |
      | 15 |  1  | 22214 |  3  | UNCHANGED |  SYNCHED  |     SYNCHED    | BLACKLIST message |        1         |

    And bug with id "2222" has rule with id "13"
    And bug with id "2222" has rule with id "14"
    And bug with id "2222" has rule with id "15"
    Then I wait for "3" seconds

    When I goto "/bugs/2222"
    When I click the "Rules" tab
    And  I check "rule_13"
    And  I check "rule_15"
    And  I click "view"
    And  I click "back"
    And  I should see the "#rule_13" checkbox checked
    And  I should see the "#rule_15" checkbox checked
    And  I should see the "#rule_14" checkbox unchecked
    And  I click "22213"
    And  I click "back"
    Then I should see the "#rule_14" checkbox checked
    And  I should see the "#rule_13" checkbox unchecked
    And  I should see the "#rule_15" checkbox unchecked


  ### Scenarios New Rule ###

  @javascript
  Scenario: New Rule: standard form: required fields
    Given a user with role "analyst" exists and is logged in
    And the current user has the following bugs:
      |  id  |
      | 2222 |
    And a "BLACKLIST" rule category exists
    And I wait for "3" seconds
    When I goto "/bugs/2222"
    And  I click the "Rules" tab
    And  I click button "create"
    And  I click "use standard form"
    And  I select "BLACKLIST" from "rule_category_id"
    And  I click "Create Rule"
    And  I wait for "2" seconds
    Then I should see "Please fill in required fields."
    When I fill in "std-form-message" with "Test msg"
    And  I fill in "std-form-detection" with "content:"200"; content:"Server: nginx/1.6.2"; content:"Transfer-Encoding: chunked"; content:"Content-Encoding: gzip"; content:"14"; fast_pattern:only; flowbits:isset,http.mokes;http_header;"
    And  I select "attempted-user" from "rule[class_type]"
    And  I select "$SSH_SERVERS" from "std-form-src"
    And  I fill in "flow_src_ports" with "$SSH_PORTS"
    And  I fill in "flow_dst_server" with "$SSH_SERVERS"
    And  I fill in "flow_dst_ports" with "$SSH_PORTS"
    And  I click "Create Rule"
    And  I wait for "1" seconds
    When I click the "Rules" tab
    And  I click button "list all"
    Then I should see a rule row with class "draft" and version "new_rule"
    And  I should see a rule row with class "new-rule" and version "new_rule"
    And  I should see a rule row with class "parsed" and version "new_rule"
    And  I should see a rule with state "NEW" version "new_rule"
    And  I should see "BLACKLIST Test msg"
#    And rule "11" is a new rule
    When I click "new_rule"
    Then I should see "BLACKLIST Test msg"
    # default flow:
    And  I should see "to_client,established"
    And  I should see "content:"200""
    And  I should see "content:"Server: nginx/1.6.2""
    And  I should see "content:"14""
    And  I should see "fast_pattern:only"
    And  I should see "flowbits:isset,http.mokes"
    And  I should see "http_header"
    And  I should see "attempted-user"
    # default metadata:
    And  I should see "pop3"
    And  I should see "imap"
    And  I should see "ftp-data"
    And  I should see "http"

  @javascript
  Scenario: New Rule: standard form: the policy options and toggle should populate checkbox values
    Given a user with role "analyst" exists and is logged in
    And the current user has the following "open_bug":
      |  id  |
      | 2222 |
    And a "BLACKLIST" rule category exists
    And I wait for "3" seconds
    When  I goto "/bugs/2222"
    And  I click the "Rules" tab
    And  I click button "create"
    And  I click "use standard form"
    And  I check "security-ips"
    Then the "security-ips" field should be "policy security-ips drop"
    When I toggle "bootstrap-switch-container"
    Then the "security-ips" field should be "policy security-ips alert"
    When I check "max-detect-ips"
    Then the "max-detect-ips" field should be "policy max-detect-ips drop"
    And  the "security-ips" field should be "policy security-ips alert"

  @javascript
  Scenario: New Rule: standard form: service options
    Given a user with role "analyst" exists and is logged in
    And the current user has the following "open_bug":
      |  id  |
      | 2222 |
    And a "BLACKLIST" rule category exists
    And I wait for "3" seconds
    When I goto "/bugs/2222"
    And  I click the "Rules" tab
    And  I click button "create"
    And  I click "use standard form"
    And  I click "other"
    And  I click "mysql"
    And  I click "kerberos"
    And  I select "BLACKLIST" from "rule_category_id"
    And  I fill in "rule[message]" with "Test Message the third"
    And  I fill in "rule[detection]" with "Detection test3"
    And  I select "unknown" from "rule[class_type]"
    And  I fill in "summary" with "This is the rule doc summary"
    # dropdown needs to be obscured to find Create Rule button
    And  I hide the element with class "other-dropdown"
    When I click "Create Rule"
    And  I wait for "1" seconds
    And  I click the "Rules" tab
    And  I click button "list all"
    And  I click "new_rule"
    Then I should see "service mysql"
    And  I should see "service kerberos"
    And  I should not see "telnet"

  @javascript
  Scenario: New Rule: standard form: rule state and css classes
    Given a user with role "analyst" exists and is logged in
    And the current user has the following "open_bug":
      |  id  |
      | 2222 |
    And a "BLACKLIST" rule category exists
    And I wait for "3" seconds
    When I goto "/bugs/2222"
    And  I click the "Rules" tab
    And  I click button "create"
    And  I click "use standard form"
    And  I select "$SSH_SERVERS" from "std-form-src"
    And  I fill in "flow_src_ports" with "$SSH_PORTS"
    And  I fill in "flow_dst_server" with "$SSH_SERVERS"
    And  I fill in "flow_dst_ports" with "$SSH_PORTS"
    And  I select "BLACKLIST" from "rule_category_id"
    And  I fill in "std-form-message" with "Test msg"
    And  I fill in "std-form-detection" with "content:"200"; content:"Server: nginx/1.6.2"; content:"Transfer-Encoding: chunked"; content:"Content-Encoding: gzip"; content:"14"; fast_pattern:only; flowbits:isset,http.mokes;"
    And  I select "attempted-user" from "rule[class_type]"
    And  I fill in "summary" with "some pig"
    And  I click "Create Rule"
    And  I wait for "1" seconds
    When I click the "Rules" tab
    And  I click button "list all"
    Then I should see a rule row with class "draft" and version "new_rule"
    And  I should see a rule row with class "new-rule" and version "new_rule"
    And  I should see a rule row with class "parsed" and version "new_rule"
    And  I should see a rule with state "NEW" version "new_rule"
    And  I should see "BLACKLIST Test msg"
#    And rule "11" is a new rule
    When I check "rule[id]"
    And  I click "edit"
    And  I fill in "rule[rule_content]" with "alert udp $HOME_NET any -> any 53 (msg:"BLACKLIST test *.msg"; flow:to_server; byte_test:1,!&,0xF8,2; content:"|04|hola|03|org|00|"; fast_pattern:only; metadata:service dns; classtype:policy-violation; rev:1;)"
    And  I click button "Save Changes"
    And  I wait for "8" seconds
    Then I should see a rule row with class "draft" and version "new_rule"
    And  I should see a rule row with class "new-rule" and version "new_rule"
    And  I should see a rule row with class "failed" and version "new_rule"
    And  I should see a rule with state "FAILED" version "new_rule"
#    And rule "11" is a new rule
    And  I should see "BLACKLIST test *.msg"

  @javascript
  Scenario: New Rule: legacy form: rule state and css classes
    Given a user with role "analyst" exists and is logged in
    And the current user has the following "open_bug":
      |  id  |
      | 2222 |
    And a "BLACKLIST" rule category exists
    And I wait for "3" seconds
    When I goto "/bugs/2222"
    And  I click the "Rules" tab
    And  I click button "create"
    And  I fill in "rule[rule_content]" with "alert udp $HOME_NET any -> any 53 (msg:"BLACKLIST test msg"; flow:to_server; byte_test:1,!&,0xF8,2; content:"|04|hola|03|org|00|"; fast_pattern:only; metadata:service dns; classtype:policy-violation;)"
    And  I fill in "summary" with "some pig"
    And  I click "Create Rule"
    And  I wait for "2" seconds
    And  I click the "Rules" tab
    And  I click button "list all"
    Then I should see a rule row with class "draft" and version "new_rule"
    And  I should see a rule row with class "new-rule" and version "new_rule"
    And  I should see a rule row with class "parsed" and version "new_rule"
    And  I should see a rule with state "NEW" version "new_rule"
    And  I should see "BLACKLIST test msg"
#    And rule "11" is a new rule

  @javascript
  Scenario: New Rule: legacy form: Rule category drop down should sort by frequency of use
    Given a user with role "analyst" exists and is logged in
    And the current user has the following "open_bug":
      |  id  |
      | 2222 |
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
    And I wait for "3" seconds
    When I goto "/bugs/2222"
    And  I click the "Rules" tab
    And  I click button "create"
    And  I fill in "rule[rule_content]" with "alert udp $HOME_NET any -> any 53 (msg:"BLACKLIST test msg"; flow:to_server; byte_test:1,!&,0xF8,2; content:"|04|hola|03|org|00|"; fast_pattern:only; metadata:service dns; classtype:policy-violation; rev:1;)"
    And  I fill in "summary" with "some pig"
    And  I click "Create Rule"
    And  I wait for "2" seconds
    When I click the "Rules" tab
    And I click button "create"
    And I click "use standard form"
    Then "BLACKLIST" should be listed first

  @javascript
  Scenario: New Rule: standard form: Rule category drop down should sort by frequency of use
    Given a user with role "analyst" exists and is logged in
    And the current user has the following "open_bug":
      |  id  |
      | 2222 |
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
    And  I goto "/bugs/2222"
    Then I click the "Rules" tab
    Then I click button "create"
    Then I click "use standard form"
    Then "OS-LINUX" should be listed first
    And  I select "BLACKLIST" from "rule_category_id"
    And  I fill in "rule[message]" with "test msg"
    And  I fill in "rule[detection]" with "|04|hola|03|org|00|"
    And  I select "attempted-user" from "rule[class_type]"
    And  I fill in "summary" with "some pig"
    Then I click "Create Rule"
    And  I wait for "3" seconds
    Then I click the "Rules" tab
    Then I click button "create"
    Then I click "use standard form"
    Then "BLACKLIST" should be listed first

  @javascript
  # Scenario: New Rule: standard form: the rule doc impact should populate based on class type selection
  Scenario: When a new rule is created, the rule doc impact should populate based on class type selection
    Given a user with role "analyst" exists and is logged in
    And the current user has the following "open_bug":
      |  id  |
      | 2222 |
    And a "BLACKLIST" rule category exists
    Then I wait for "3" seconds
    And  I goto "/bugs/2222"
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

  # Scenario: New Rule: legacy form the rule doc impact should populate based on class type selection
  ### Scenarios Existing Rule ###
  # Scenario: Existing Rule: Viewing existing synched rule
  # Scenario: Existing Rule: Viewing existing parsed new rule
  # Scenario: Existing Rule: Viewing existing failed new rule
  # Scenario: Existing Rule: Viewing existing parsed edited rule
  # Scenario: Existing Rule: Viewing existing failed edited rule
  # Scenario: Existing Rule: Viewing existing parsed stale edit rule
  # Scenario: Existing Rule: Viewing existing failed stale edit rule
  # Scenario: Existing Rule: One or more rules can be selected on a bug to view or edit
  ### Scenarios Editing Rule ###
  # Scenario: Edit Rule: A rule can be edited
  # Scenario: a user can edit rule docs for a new rule


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
      | id | gid |  sid  | rev |   state   |edit_status| publish_status |     message       | rule_category_id |
      | 11 |  1  | 22211 |  3  | UNCHANGED |  SYNCHED  |     SYNCHED    | BLACKLIST message |        1         |
    Then rule "11" is synched
    And bug with id "2222" has rule with id "11"
    When I goto "/bugs/2222"
    And I click the "Rules" tab
    And I click button "list all"
    Then I should see rule "11" state "UNCHANGED" version "1:22211:3"
    And I should see "BLACKLIST message"
    And I should see a rule row with class "synched" and id "11"


  # ==== Editing a rule ===

  @javascript
  Scenario: One or more rules can be selected on a bug to view or edit
    Given a user with role "analyst" exists and is logged in
    And the following rule categories exist:
      | category        | id |
      | BROWSER-PLUGINS |  1 |
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
      | id | gid |  sid  | rev |   state   |edit_status| publish_status |     message       | rule_category_id |
      | 11 |  1  | 22211 |  3  | UNCHANGED |  SYNCHED  |    SYNCHED     | BLACKLIST message |        1         |
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
    And  I fill in "rule[rule_content]" with "alert udp $HOME_NET any -> any 53 (msg:"BLACKLIST test msg"; flow:to_server; byte_test:1,!&,0xF8,2; content:"|04|hola|03|org|00|"; fast_pattern:only; metadata:service dns; classtype:policy-violation; sid:22211; rev:3;)"
    And  I click button "Save Changes"
    And  I wait for "8" seconds
    Then I should see rule "11" state "UPDATED" version "1:22211:3"
    And rule "11" is a current edit
    And I should see "BLACKLIST test msg"
    And I should see a rule row with class "draft" and id "11"
    And I should see a rule row with class "edited-rule" and id "11"
    And I should see a rule row with class "current-edit" and id "11"
    And I should see a rule row with class "parsed" and id "11"

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
      | id | gid |  sid  | rev |   state   |edit_status| publish_status |     message       | rule_category_id |
      | 11 |  1  | 22211 |  3  | UNCHANGED |  SYNCHED  |     SYNCHED    | BLACKLIST message |        1         |
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
    And  I fill in "rule[rule_content]" with "alert (msg:"BLACKLIST test msg"; flow:to_server; byte_test:1,!&,0xF8,2; content:"|04|hola|03|org|00|"; fast_pattern:only; metadata:service dns; classtype:policy-violation; sid:22211; rev:3;)"
    And  I click button "Save Changes"
    And  I wait for "8" seconds
    Then I should see rule "11" state "FAILED" version "1:22211:3"
    And rule "11" is a current edit
    And I should see "BLACKLIST test msg"
    And I should see a rule row with class "draft" and id "11"
    And I should see a rule row with class "edited-rule" and id "11"
    And I should see a rule row with class "current-edit" and id "11"
    And I should see a rule row with class "failed" and id "11"


  # ==== Synching a rule from VC ===

  @javascript
  Scenario: VC updated for a valid edited rule
    Given a user with role "analyst" exists and is logged in
    And I wait for "3" seconds
    Given the following bugs exist:
      |  id  | bugzilla_id | state  | user_id |
      | 2222 |   222222    | OPEN   |    1    |
    And the following rule categories exist:
      | category  | id |
      | BLACKLIST |  1 |
    And the following rules exist:
      | id | gid |  sid  | rev |   state   |edit_status| publish_status |     message       | rule_category_id |
      | 11 |  1  | 22211 |  3  |  UPDATED  |   EDIT    |  CURRENT_EDIT  | BLACKLIST message |        1         |
    And bug with id "2222" has rule with id "11"
    When rule sid "22211" rev "4" is synched
    And  I goto "/bugs/2222"
    And  I click the "Rules" tab
    And  I click button "list all"
    Then I should see "BLACKLIST message"
    And I should see a rule row with class "draft" and id "11"
    And I should see a rule row with class "edited-rule" and id "11"
    And I should see a rule row with class "stale-edit" and id "11"
    And I should see a rule row with class "parsed" and id "11"

  @javascript
  Scenario: VC updated for a failed parsing edited rule
    Given a user with role "analyst" exists and is logged in
    And I wait for "3" seconds
    Given the following bugs exist:
      |  id  | bugzilla_id | state  | user_id |
      | 2222 |   222222    | OPEN   |    1    |
    And the following rule categories exist:
      | category  | id |
      | BLACKLIST |  1 |
    And the following rules exist:
      | id | gid |  sid  | rev |   state   |edit_status| publish_status |parsed|     message       | rule_category_id |
      | 11 |  1  | 22211 |  3  |   FAILED  |   EDIT    |  CURRENT_EDIT  |false | BLACKLIST message |        1         |
    And bug with id "2222" has rule with id "11"
    When rule sid "22211" rev "4" is synched
    And  I goto "/bugs/2222"
    And  I click the "Rules" tab
    And  I click button "list all"
    Then I should see "BLACKLIST message"
    And I should see a rule row with class "draft" and id "11"
    And I should see a rule row with class "edited-rule" and id "11"
    And I should see a rule row with class "stale-edit" and id "11"
    And I should see a rule row with class "failed" and id "11"


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


  Scenario: Editing Rule: A rule can revert_grep model test
    Given the following rules exist:
      | id | gid |  sid  | rev |  state  |edit_status|publish_status|parsed|
      |  7 |  1  | 22211 |  3  | UPDATED |   EDIT    | CURRENT_EDIT | true |
    When code calls revert_grep for rule gid "1" sid "22211" on "extras/snort/rules/app-detect.rules:33:# alert udp $HOME_NET any -> any 53 (msg:"BLACKLIST test msg"; flow:to_server; byte_test:1,!&,0xF8,2; content:"|04|hola|03|org|00|"; fast_pattern:only; metadata:service dns; classtype:policy-violation; sid:22211; rev:4;)"
    Then a rule record for rule gid "1" sid "22211" will exist
    And  A rule gid "1" and sid "22211" has class "synched"
    And  A rule gid "1" and sid "22211" has class "parsed"
    And  A rule gid "1" and sid "22211" has rev "4"

  Scenario: Editing Rule: A rule can revert model test
    Given the following rules exist:
      | id | gid |  sid  | rev |  state  |edit_status|publish_status|parsed|               rule_content               |
      |  7 |  1  | 19500 |  3  | UPDATED |   EDIT    | CURRENT_EDIT |false | alert (msg: "the promised one has come") |
    When code calls revert_rules_action for rule gid "1" sid "19500"
    Then a rule record for rule gid "1" sid "19500" will exist
    And  A rule gid "1" and sid "19500" has class "synched"
    And  A rule gid "1" and sid "19500" has class "parsed"

  ### Scenarios Synching a rule from VC ###

  Scenario: Synch Rule: create a valid rule from synching model test
    When code calls load_grep on "extras/snort/rules/app-detect.rules:33:# alert udp $HOME_NET any -> any 53 (msg:"BLACKLIST test msg"; flow:to_server; byte_test:1,!&,0xF8,2; content:"|04|hola|03|org|00|"; fast_pattern:only; metadata:service dns; classtype:policy-violation; sid:22211; rev:4;)"
    Then a rule record for rule gid "1" sid "22211" will exist
    And  A rule gid "1" and sid "22211" has class "synched"
    And  A rule gid "1" and sid "22211" has class "parsed"

  Scenario: Synch Rule: create a failed rule from synching model test
    When code calls load_grep on "extras/snort/rules/app-detect.rules:33:# alert udp $HOME_NET any -> any 53 (msg:"BLACKLIST test *.msg"; flow:to_server; byte_test:1,!&,0xF8,2; content:"|04|hola|03|org|00|"; fast_pattern:only; metadata:service dns; classtype:policy-violation; sid:22211; rev:4;)"
    Then a rule record for rule gid "1" sid "22211" will exist
    And  A rule gid "1" and sid "22211" has class "synched"
    And  A rule gid "1" and sid "22211" has class "failed"

  Scenario: Synch Rule: update an existing valid synched rule with new rev model test
    Given the following rules exist:
      | id | gid |  sid  | rev | state     |
      | 11 |  1  | 22211 |  3  | UNCHANGED |
    When code calls load_grep on "extras/snort/rules/app-detect.rules:33:# alert udp $HOME_NET any -> any 53 (msg:"BLACKLIST test msg"; flow:to_server; byte_test:1,!&,0xF8,2; content:"|04|hola|03|org|00|"; fast_pattern:only; metadata:service dns; classtype:policy-violation; sid:22211; rev:4;)"
    Then a rule record for rule gid "1" sid "22211" will exist
    And  A rule gid "1" and sid "22211" has class "synched"
    And  A rule gid "1" and sid "22211" has class "parsed"
    And  A rule gid "1" and sid "22211" has rev "4"

  Scenario: Synch Rule: update an existing valid synched rule with same rev model test
    Given the following rules exist:
      | id | gid |  sid  | rev | state     |
      | 11 |  1  | 22211 |  4  | UNCHANGED |
    When code calls load_grep on "extras/snort/rules/app-detect.rules:33:# alert udp $HOME_NET any -> any 53 (msg:"BLACKLIST test msg"; flow:to_server; byte_test:1,!&,0xF8,2; content:"|04|hola|03|org|00|"; fast_pattern:only; metadata:service dns; classtype:policy-violation; sid:22211; rev:4;)"
    Then a rule record for rule gid "1" sid "22211" will exist
    And  A rule gid "1" and sid "22211" has class "synched"
    And  A rule gid "1" and sid "22211" has class "parsed"
    And  A rule gid "1" and sid "22211" has rev "4"

  Scenario: Synch Rule: VC updated for a valid edited rule do not load model test
    Given the following rules exist:
      | id | gid |  sid  | rev |  state  |edit_status|publish_status|parsed|
      |  7 |  1  | 22211 |  3  | UPDATED |   EDIT    | CURRENT_EDIT | true |
    When code calls load_grep on "extras/snort/rules/app-detect.rules:33:# alert udp $HOME_NET any -> any 53 (msg:"BLACKLIST test msg"; flow:to_server; byte_test:1,!&,0xF8,2; content:"|04|hola|03|org|00|"; fast_pattern:only; metadata:service dns; classtype:policy-violation; sid:22211; rev:4;)"
    Then a rule record for rule gid "1" sid "22211" will exist
    And  A rule gid "1" and sid "22211" has class "draft"
    And  A rule gid "1" and sid "22211" has class "edited-rule"
    And  A rule gid "1" and sid "22211" has class "stale-edit"
    And  A rule gid "1" and sid "22211" has class "parsed"
    And  A rule gid "1" and sid "22211" has rev "3"

  Scenario: Synch Rule: VC updated for a failed edited rule do not load model test
    Given the following rules exist:
      | id | gid |  sid  | rev |  state  |edit_status|publish_status|parsed|
      |  7 |  1  | 22211 |  3  | FAILED  |   EDIT    | CURRENT_EDIT | false|
    When code calls load_grep on "extras/snort/rules/app-detect.rules:33:# alert udp $HOME_NET any -> any 53 (msg:"BLACKLIST test msg"; flow:to_server; byte_test:1,!&,0xF8,2; content:"|04|hola|03|org|00|"; fast_pattern:only; metadata:service dns; classtype:policy-violation; sid:22211; rev:4;)"
    Then a rule record for rule gid "1" sid "22211" will exist
    And  A rule gid "1" and sid "22211" has class "draft"
    And  A rule gid "1" and sid "22211" has class "edited-rule"
    And  A rule gid "1" and sid "22211" has class "stale-edit"
    And  A rule gid "1" and sid "22211" has class "failed"
    And  A rule gid "1" and sid "22211" has rev "3"



  ### Scenarios should_be_on method ###

  Scenario: should_be_on: should be off model test
    Given the following rules exist:
      | id | gid |  sid  | metadata                                             | detection         |
      |  7 |  1  | 22211 | policy max-detect-ips drop, policy security-ips drop | flowbits:noalert; |
    Then a rule gid "1" and sid "22211" should be off

  Scenario: should_be_on: balanced-ips is on model test
    Given the following rules exist:
      | id | gid |  sid  | metadata                                             | detection         |
      |  7 |  1  | 22211 | policy balanced-ips drop, policy security-ips drop   | flowbits:noalert; |
    Then a rule gid "1" and sid "22211" should be on

  Scenario: should_be_on: connectivity-ips is on model test
    Given the following rules exist:
      | id | gid |  sid  | metadata                                                 | detection         |
      |  7 |  1  | 22211 | policy max-detect-ips drop, policy connectivity-ips drop | flowbits:noalert; |
    Then a rule gid "1" and sid "22211" should be on

  Scenario: should_be_on: flowbits set is on model test
    Given the following rules exist:
      | id | gid |  sid  | metadata                                             | detection                           |
      |  7 |  1  | 22211 | policy max-detect-ips drop, policy security-ips drop | flowbits:set,sybase.tds.connection; |
    Then a rule gid "1" and sid "22211" should be on

  Scenario: Onoff: uncommented rule content should be on when it should be on model test
    Given the following rules exist:
      | gid |  sid  | metadata                 | detection         | rule_content             |
      |  1  | 22211 | policy balanced-ips drop | flowbits:noalert; | alert (degenerate: yes;) |
    Then a rule gid "1" and sid "22211" is on

  Scenario: Onoff: uncommented rule content should be off when it should be off model test
    Given the following rules exist:
      | gid |  sid  | metadata                 | detection         | rule_content             |
      |  1  | 22211 | policy security-ips drop | flowbits:noalert; | alert (degenerate: yes;) |
    Then a rule gid "1" and sid "22211" is off

  Scenario: Onoff: commented rule content should be on when it should be on model test
    Given the following rules exist:
      | gid |  sid  | metadata                 | detection         | rule_content             |
      |  1  | 22211 | policy balanced-ips drop | flowbits:noalert; | # alert (degenerate: yes;) |
    Then a rule gid "1" and sid "22211" is on

  Scenario: Onoff: commented rule content should be off when it should be off model test
    Given the following rules exist:
      | gid |  sid  | metadata                 | detection         | rule_content             |
      |  1  | 22211 | policy security-ips drop | flowbits:noalert; | # alert (degenerate: yes;) |
    Then a rule gid "1" and sid "22211" is off

