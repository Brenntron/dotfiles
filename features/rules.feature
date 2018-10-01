Feature: Rules
  In order to import, create or edit rules
  as a user
  I will provides ways to interact with rules

    ### Rules tab navigation ###

  ### Scenarios Export Rule ###
  @javascript
  Scenario: Selecting no rules with a bug with rules exports all rules
    Given a user with role "committer" exists and is logged in
    Given the following bugs exist:
      |  id  | bugzilla_id | state  | user_id |
      | 2222 |   222222    | OPEN   |    1    |
    Given the following rule categories exist:
      | category  | id |
      | APP-DETECT |  1 |
    When the following "synched_rule" rules exist:
      | id | gid |  sid  | rev |     message       | rule_category_id |
      | 13 |  1  | 22212 |  3  | APP-DETECT message |        1         |
      | 14 |  1  | 22213 |  3  | APP-DETECT message |        1         |
      | 15 |  1  | 22214 |  3  | APP-DETECT message |        1         |

    And bug with id "2222" has rule with id "13"
    And bug with id "2222" has rule with id "14"
    And bug with id "2222" has rule with id "15"
    Then I wait for "3" seconds

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


  # ==== Deleted rules ===

# We may implement this in the future...delete if not used after 5/2018

#  @javascript
#  Scenario: A rule with a rule category of deleted should not be visible
#    Given a user with role "analyst" exists and is logged in
#    And I wait for "3" seconds
#    Given the following bugs exist:
#      |  id  | bugzilla_id | state  | user_id |
#      | 2222 |   222222    | OPEN   |    1    |
#    And the following rule categories exist:
#      | category  | id |
#      | DELETED   |  1 |
#      | APP-DETECT |  2 |
#    And the following rules exist:
#      | id | gid |  sid  | rev |   state   |edit_status| publish_status |     message                | rule_category_id |
#      | 11 |  1  | 22211 |  3  |  UPDATED  |   EDIT    |  CURRENT_EDIT  | DELETED message test       |        1         |
#      | 12 |  1  | 22212 |  3  | UNCHANGED |  SYNCHED  |     SYNCHED    | APP-DETECT message          |        2         |
#    And bug with id "2222" has rule with id "11"
#    And bug with id "2222" has rule with id "12"
#    And  I goto "/bugs/2222"
#    And  I click the "Rules" tab
#    And  I click button "list all"
#    And I should see "APP-DETECT message"
#    And I should not see "DELETED message test"


  # ==== Editing rule docs ===

# TODO: Fix test: textarea value is not being set correctly within test
#  @javascript  
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
    Given the following "edited_rule" rules exist:
      | id | gid |  sid  | rev |parsed|
      |  7 |  1  | 22211 |  3  | true |
    When code calls revert_grep for rule gid "1" sid "22211" on "extras/snort/rules/app-detect.rules:33:# alert udp $HOME_NET any -> any 53 (msg:"APP-DETECT test msg"; flow:to_server; byte_test:1,!&,0xF8,2; content:"|04|hola|03|org|00|"; fast_pattern:only; metadata:service dns; classtype:policy-violation; sid:22211; rev:4;)"
    Then a rule record for rule gid "1" sid "22211" will exist
    And  A rule gid "1" and sid "22211" has class "synched"
    And  A rule gid "1" and sid "22211" has class "parsed"
    And  A rule gid "1" and sid "22211" has rev "4"

  Scenario: Editing Rule: A rule can revert model test
    Given the following "edited_rule" rules exist:
      | id | gid |  sid  | rev |parsed|               rule_content               |
      |  7 |  1  | 19500 |  3  |false | alert (msg: "the promised one has come") |
    When code calls revert_rules_action for rule gid "1" sid "19500"
    Then a rule record for rule gid "1" sid "19500" will exist
    And  A rule gid "1" and sid "19500" has class "synched"
    And  A rule gid "1" and sid "19500" has class "parsed"

  ### Scenarios Synching a rule from VC ###
   
  Scenario: Synch Rule: create a valid rule from synching model test
    When code calls load_grep on "extras/snort/rules/app-detect.rules:33:# alert udp $HOME_NET any -> any 53 (msg:"APP-DETECT test msg"; flow:to_server; byte_test:1,!&,0xF8,2; content:"|04|hola|03|org|00|"; fast_pattern:only; metadata:service dns; classtype:policy-violation; sid:22211; rev:4;)"
    Then a rule record for rule gid "1" sid "22211" will exist
#    And  A rule gid "1" and sid "22211" has class "synched"
    And  A rule gid "1" and sid "22211" has class "parsed"
   
  Scenario: Synch Rule: create a failed rule from synching model test
    When code calls load_grep on "extras/snort/rules/app-detect.rules:33:# alert udp $HOME_NET any -> any 53 (msg:"APP-DETECT test *.msg"; flow:to_server; byte_test:1,!&,0xF8,2; content:"|04|hola|03|org|00|"; fast_pattern:only; metadata:service dns; classtype:policy-violation; sid:22211; rev:4;)"
    Then a rule record for rule gid "1" sid "22211" will exist
#    And  A rule gid "1" and sid "22211" has class "synched"
    And  A rule gid "1" and sid "22211" has class "incomplete-unparsed"
   
  Scenario: Synch Rule: update an existing valid synched rule with new rev model test
    Given the following "synched_rule" rules exist:
      | id | gid |  sid  | rev |parsed|
      | 11 |  1  | 22211 |  3  | true |
    When code calls load_grep on "extras/snort/rules/app-detect.rules:33:# alert udp $HOME_NET any -> any 53 (msg:"APP-DETECT test msg"; flow:to_server; byte_test:1,!&,0xF8,2; content:"|04|hola|03|org|00|"; fast_pattern:only; metadata:service dns; classtype:policy-violation; sid:22211; rev:4;)"
    Then a rule record for rule gid "1" sid "22211" will exist
    And  A rule gid "1" and sid "22211" has class "synched"
    And  A rule gid "1" and sid "22211" has class "parsed"
    And  A rule gid "1" and sid "22211" has rev "4"
   
  @javascript
  Scenario: Synch Rule: update an existing valid synched rule with same rev model test
    Given the following "synched_rule" rules exist:
      | id | gid |  sid  | rev |parsed|
      | 11 |  1  | 22211 |  4  | true |
    When code calls load_grep on "extras/snort/rules/app-detect.rules:33:# alert udp $HOME_NET any -> any 53 (msg:"APP-DETECT test msg"; flow:to_server; byte_test:1,!&,0xF8,2; content:"|04|hola|03|org|00|"; fast_pattern:only; metadata:service dns; classtype:policy-violation; sid:22211; rev:4;)"
    Then a rule record for rule gid "1" sid "22211" will exist
    And  A rule gid "1" and sid "22211" has class "synched"
    And  A rule gid "1" and sid "22211" has class "parsed"
    And  A rule gid "1" and sid "22211" has rev "4"

  Scenario: Synch Rule: VC updated for a valid edited rule do not load model test
    Given the following "edited_rule" rules exist:
      | id | gid |  sid  | rev |parsed|
      |  7 |  1  | 22211 |  3  | true |
    When code calls load_grep on "extras/snort/rules/app-detect.rules:33:# alert udp $HOME_NET any -> any 53 (msg:"APP-DETECT test msg"; flow:to_server; byte_test:1,!&,0xF8,2; content:"|04|hola|03|org|00|"; fast_pattern:only; metadata:service dns; classtype:policy-violation; sid:22211; rev:4;)"
    Then a rule record for rule gid "1" sid "22211" will exist
    And  A rule gid "1" and sid "22211" has class "draft"
    And  A rule gid "1" and sid "22211" has class "edited-rule"
    And  A rule gid "1" and sid "22211" has class "stale-edit"
    And  A rule gid "1" and sid "22211" has class "parsed"
    And  A rule gid "1" and sid "22211" has rev "3"
    And  A rule id "7" should have state "STALE"

  Scenario: Synch Rule: VC updated for a failed edited rule do not load model test
    Given the following "edited_rule" rules exist:
      | id | gid |  sid  | rev |  state  |parsed|
      |  7 |  1  | 22211 |  3  | FAILED  | false|
    When code calls load_grep on "extras/snort/rules/app-detect.rules:33:# alert udp $HOME_NET any -> any 53 (msg:"APP-DETECT test msg"; flow:to_server; byte_test:1,!&,0xF8,2; content:"|04|hola|03|org|00|"; fast_pattern:only; metadata:service dns; classtype:policy-violation; sid:22211; rev:4;)"
    Then a rule record for rule gid "1" sid "22211" will exist
    And  A rule gid "1" and sid "22211" has class "draft"
    And  A rule gid "1" and sid "22211" has class "edited-rule"
    And  A rule gid "1" and sid "22211" has class "stale-edit"
    And  A rule gid "1" and sid "22211" has class "incomplete-unparsed"
    And  A rule gid "1" and sid "22211" has rev "3"
    And  A rule id "7" should have state "STALE"




  ### Scenarios should_be_on method ###

  Scenario: should_be_on: should be off model test
    Given the following "edited_rule" rules exist:
      | id | gid |  sid  | metadata                                             | detection         |
      |  7 |  1  | 22211 | policy max-detect-ips drop, policy security-ips drop | flowbits:noalert; |
    Then a rule gid "1" and sid "22211" should be off

  Scenario: should_be_on: balanced-ips is on model test
    Given the following "edited_rule" rules exist:
      | id | gid |  sid  | metadata                                             | detection         |
      |  7 |  1  | 22211 | policy balanced-ips drop, policy security-ips drop   | flowbits:noalert; |
    Then a rule gid "1" and sid "22211" should be on

  Scenario: should_be_on: connectivity-ips is on model test
    Given the following "edited_rule" rules exist:
      | id | gid |  sid  | metadata                                                 | detection         |
      |  7 |  1  | 22211 | policy max-detect-ips drop, policy connectivity-ips drop | flowbits:noalert; |
    Then a rule gid "1" and sid "22211" should be on

  Scenario: should_be_on: flowbits set is on model test
    Given the following "edited_rule" rules exist:
      | id | gid |  sid  | metadata                                             | detection                           |
      |  7 |  1  | 22211 | policy max-detect-ips drop, policy security-ips drop | flowbits:set,sybase.tds.connection; |
    Then a rule gid "1" and sid "22211" should be on

  Scenario: Onoff: uncommented rule content should be on when it should be on model test
    Given the following "edited_rule" rules exist:
      | gid |  sid  | metadata                 | detection         | rule_content             |
      |  1  | 22211 | policy balanced-ips drop | flowbits:noalert; | alert (degenerate: yes;) |
    Then a rule gid "1" and sid "22211" is on

  Scenario: Onoff: uncommented rule content should be off when it should be off model test
    Given the following "edited_rule" rules exist:
      | gid |  sid  | metadata                 | detection         | rule_content             |
      |  1  | 22211 | policy security-ips drop | flowbits:noalert; | alert (degenerate: yes;) |
    Then a rule gid "1" and sid "22211" is off

  Scenario: Onoff: commented rule content should be on when it should be on model test
    Given the following "edited_rule" rules exist:
      | gid |  sid  | metadata                 | detection         | rule_content             |
      |  1  | 22211 | policy balanced-ips drop | flowbits:noalert; | # alert (degenerate: yes;) |
    Then a rule gid "1" and sid "22211" is on

  Scenario: Onoff: commented rule content should be off when it should be off model test
    Given the following "edited_rule" rules exist:
      | gid |  sid  | metadata                 | detection         | rule_content             |
      |  1  | 22211 | policy security-ips drop | flowbits:noalert; | # alert (degenerate: yes;) |
    Then a rule gid "1" and sid "22211" is off



  @javascript
  Scenario: I need to ensure the local file grep regex works properly
    Then pending
    When code calls grep_line_from_file with sid "1" and gid "139" the response should include "; sid: 1; gid: 139; rev: 1; metadata: rule-type preproc ; classtype:sdf; )"
    And  code calls grep_line_from_file with sid "98" and gid "116" the response should include "; sid:98; gid:116; rev:1; metadata:rule-type decode; classtype:protocol-command-decode; )"
