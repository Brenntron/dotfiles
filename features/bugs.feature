Feature: Bug
  In order to import, create or edit bugs
  as a user
  I will provides ways to interact with bugs


  @javascript
  Scenario: A user can view and filter bugs
    Given a user with role "analyst" exists and is logged in
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
    Given a user with role "analyst" exists and is logged in
    And the following tags exist:
      | name  |
      | TELUS |
      | VULN  |
      | BP    |
    Then I wait for "3" seconds
    And  I goto "/bugs/new"
    And  I fill in "bug_summary" with "New Bug Summary"
    And  I fill in "bug_description" with "This is my description."
    And  I fill in selectized with "TELUS"
    Then I click "Create Bug"
    Then I should see "[TELUS]New Bug Summary"
    And  the selectize field contains the text "TELUS"



  # ==== Editing Tags ===
  @javascript
  Scenario: The summary text should update with tag edits
    Given a user with role "analyst" exists and is logged in
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
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
    Then I wait for "3" seconds
    And I goto "/bugs"
    Then I should see "[BP][NSS] fixed bug"
    And I wait for "1" seconds
    When I click "delete_bug222222"
    And I wait for "1" seconds
    And I goto "/bugs"
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
    Given a user with role "analyst" exists and is logged in
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
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       | committer_id |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |     1        |
    And the following rules exist belonging to bug "222222":
      |id | message                 | rule_category_id |
      |1  | BLACKLIST message       | 1                |
    And the following references exist:
      | id | reference_data | reference_type_id |
      | 1  | 2006-5745      | 1                 |
    And the following exploits exist:
      | id | data                                                                                        | exploit_type_id |
      | 1  | exploits/ms06_071/ms06_071.py - http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2006-5745 | 1               |
    And rule with id "1" has a reference with id "1"
    And reference with id "1" has exploit with id "1"
    Then I wait for "2" seconds
    And I goto "/bugs/222222"
    And I click "change_state"
    Then I should see "Cant set to pending."
    And I can not select "PENDING" from "state"

  @javascript
  Scenario: a user can not set the state of a bug to fixed, wontfix, later or invalid if they aren't a committer
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       | committer_id |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |     1        |
    Then I wait for "2" seconds
    And I goto "/bugs/222222"
    And I click "change_state"
    And the "FIXED" option from "state" is disabled
    And the "REOPENED" option from "state" is not disabled

  @javascript
  Scenario: a user can set the state of a bug to fixed, wontfix, later or invalid if they are a committer
    Given a user with role "committer" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       | committer_id |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |     1        |
    Then I wait for "2" seconds
    And I goto "/bugs/222222"
    And I click "change_state"
    And the "FIXED" option from "state" is not disabled
    And the "REOPENED" option from "state" is not disabled


  @javascript
  Scenario: a user can return to the index from viewing a bug
    Given a user with role "analyst" exists and is logged in
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
            the committer of the bug should not be availabe for the editor dropdown
    Given a user with role "analyst" exists and is logged in

    And the following users exist
      | id | email                | cvs_username  | display_name        | parent_id |
      | 2  | rainbows@email.com   | rainbow_b     | Rainbow Brite       | 1         |
      | 3  | hclinton@email.com   | h_clinton     | Hillary Clinton     | 2         |
      | 4  | dtrump@email.com     | d_drumph      | Donald Trump        | 1         |
      | 5  | gjohns@email.com     | g_johnson     | Gary Johnson        |           |
      | 6  | tbeary@email.com     | t_bear        | Teddy Bear          | 2         |

    And the following roles exist:
      | role           |
      | committer      |
      | manager        |

    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       | committer_id |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |  6           |

    And a user with id "2" has a role of "manager"
    And a user with id "6" has a role of "committer"

    Then I wait for "3" seconds
    And I goto "/bugs/222222"
    Then I click "editor"
    And "rainbow_b" should be in the "bug_editor" dropdown list
    And "t_bear" should not be in the "bug_editor" dropdown list
    And I select "rainbow_b" from "bug_editor"
    Then I click button "change editor"
    And I wait for "3" seconds
# uncomment when connectivity to bugzilla test fixed
# And I should see "rainbow_b"

  @javascript
  Scenario: a user can change the committer of a bug
            only a user with role committer should be available in the dropdown
            user assigned as editor cannot be in the committer dropdown
    Given a user with role "analyst" exists and is logged in

    And the following users exist
      | id | email                | cvs_username  | display_name        | parent_id |
      | 2  | rainbows@email.com   | rainbow_b     | Rainbow Brite       | 1         |
      | 3  | hclinton@email.com   | h_clinton     | Hillary Clinton     | 2         |
      | 4  | dtrump@email.com     | d_drumph      | Donald Trump        | 1         |
      | 5  | gjohns@email.com     | g_johnson     | Gary Johnson        |           |
      | 6  | tbeary@email.com     | t_bear        | Teddy Bear          | 2         |

    And the following roles exist:
      | role           |
      | committer      |
      | manager        |

    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       | user_id |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |  4      |

    And a user with id "4" has a role of "committer"
    And a user with id "6" has a role of "committer"

    Then I wait for "3" seconds
    And I goto "/bugs/222222"
    Then I click "committer"
    And "t_bear" should be in the "bug_committer" dropdown list
    And "d_drumph" should not be in the "bug_committer" dropdown list
    And I select "t_bear" from "bug_committer"
    Then I click button "change committer"
    And I wait for "3" seconds
# uncomment when connectivity to bugzilla test fixed
# And I should see "t_bear"

  @javascript
  Scenario: a user can change the priority of a bug
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
    Then I wait for "3" seconds
    And I goto "/bugs/222222"
    Then I click "priority"
    And I select "P2" from "priority"
    Then I click button "change priority"
    And I wait for "3" seconds
# uncomment when connectivity to bugzilla test fixed
#    And I should see "P2"

  @javascript
  Scenario: a user can change the component of a bug
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
       | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
       | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
    Then I wait for "3" seconds
    And I goto "/bugs/222222"
    Then I click "component"
    And I select "Malware" from "component"
    Then I click button "change component"
    And I wait for "3" seconds
# uncomment when connectivity to bugzilla test fixed
#    Then I should see "Malware"

  @javascript
  Scenario: a user can change the summary of a bug
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
    Then I wait for "3" seconds
    And I goto "/bugs/222222"
    Then I click "summary"
    And I fill in "bug_summary" with "new summary"
#    Then I click button "change summary"
#    And I wait for "2" seconds
# uncomment when connectivity to bugzilla test fixed
# Then I should see "new summary"


  @javascript
  Scenario: a user can add a new rule to a bug
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
    And the following reference types exist:
      | id | name    | description  | example |
      | 1  | cve     | just a thing | 222-222 |
      | 2  | url     | just a thing | 222-222 |
      | 3  | bugtraq | just a thing | 222-222 |
    Then I wait for "3" seconds
    And I goto "/bugs/222222"
    And I click ".rules-tab"
    And I click button "create"
    And  I fill in "rule[rule_content]" with "alert tcp $EXTERNAL_NET  ->  $HOME_NET any (msg:"select a category ";flow:to_client,established;detection:;metadata: balanced-ips, security-ips, drop, ftp-data, http, imap, pop3, , ;reference:cve,2006-5745; reference:cve,2568-5014; classtype:attempted-user)"
    And I fill in "summary" with "this is the summary"
    Then I click button "Create Rule"
    Then I click ".rules-tab"
    And I should see "new_rule"
    And I should see "select a category"

  @javascript
  Scenario: a user can add a new rule to a bug only if all required fields are filled out
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
    And the following reference types exist:
      | id | name    | description  | example |
      | 1  | cve     | just a thing | 222-222 |
      | 2  | url     | just a thing | 222-222 |
      | 3  | bugtraq | just a thing | 222-222 |
    Then I wait for "3" seconds
    And I goto "/bugs/222222"
    And I click ".rules-tab"
    And I click button "create"
    And  I fill in "rule[rule_content]" with "alert tcp $EXTERNAL_NET  ->  $HOME_NET any (msg:"select a category ";flow:to_client,established;detection:;metadata: balanced-ips, security-ips, drop, ftp-data, http, imap, pop3, , ;reference:cve,2006-5745; reference:cve,2568-5014; classtype:attempted-user)"
    Then I click button "Create Rule"
    Then I wait for "2" seconds
    Then I should see "Please fill in required fields."
    Then I fill in "summary" with "This is the summary"
    Then I click button "Create Rule"
    Then I click ".rules-tab"
    And I should see "new_rule"
    And I should see "select a category"

  @javascript
  Scenario: a user can add a new rule and the rule doc impact will populate after save
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
    And the following reference types exist:
      | id | name    | description  | example |
      | 1  | cve     | just a thing | 222-222 |
      | 2  | url     | just a thing | 222-222 |
      | 3  | bugtraq | just a thing | 222-222 |
    Then I wait for "3" seconds
    And I goto "/bugs/222222"
    And I click ".rules-tab"
    And I click button "create"
    And I fill in "rule[rule_content]" with "alert tcp $EXTERNAL_NET  ->  $HOME_NET any (msg:'select a category ';flow:to_client,established;detection:;metadata: balanced-ips, security-ips, drop, ftp-data, http, imap, pop3, , ;reference:cve,2006-5745; reference:cve,2568-5014; classtype:attempted-user)"
    And I fill in "summary" with "this is the summary"
    Then I click button "Create Rule"
    Then I click ".rules-tab"
    Then I click "new_rule"
    And I should see "select a category"
    And I should see "this is the summary"
    And I should see "Attempted User Privilege Gain"


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
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
    And a rule exists and belongs to bug "222222"
    Then I wait for "3" seconds
    And I goto "/bugs/222222"
    And I click ".rules-tab"



  @javascript
  Scenario: a user can edit a rule attached to a bug
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
    And the following reference types exist:
      | id | name    | description  | example |
      | 1  | cve     | just a thing | 222-222 |
      | 2  | url     | just a thing | 222-222 |
      | 3  | bugtraq | just a thing | 222-222 |
    And a rule exists and belongs to bug "222222"
    Then I wait for "3" seconds
    And I goto "/bugs/222222"
    And I click ".rules-tab"
    And I toggle checkbox ".rule_1"
    Then I should see "ActiveX clsid access attempt"
    And I click button "edit"
    And  I fill in "rule[rule_content]" with "connection:drop ip $DNS_SERVERS $ORACLE_PORTS -> $SMTP_SERVERS $HOME_NET any (msg:'BROWSER-IE You are the worst if you use IE';flow:to_client,established;detection:So many detections;metadata: balanced-ips, drop, ftp-data, http, imap, pop3, red, community;reference:bugtraq,122344; classtype:attempted-user; sid:12345; rev:3)"
    When I click button "Save Changes"
    And I click ".rules-tab"
    Then I should not see "ActiveX clsid access attempt"
    And I should see "are the worst"

  @javascript
  Scenario: a user can test a rule
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state    | user_id | summary                            | product  | component   | version |      description       |
      | 145359 | 145359      | REOPENED | 1       | [SID] 15539 This is a fake bug!!!! | Research | Snort Rules | 2.6.0   | This is a fake bug!!!! |
    And a rule exists and belongs to bug "145359"
    And I wait for "3" seconds
    When I goto "/bugs/145359"
    And I click ".jobs-tab"
    Then I should not see "rule"
    And I click ".rules-tab"
    And I toggle checkbox ".rule_1"
    Then I should see "ActiveX clsid access attempt"
    When I click button "test"
    Then test should be created and I should see "Task has been created to test the rule"
    And I click ".jobs-tab"
    Then I should see "rule"

  @javascript
  Scenario: a user can test add an attachment
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state    | user_id | summary                            | product  | component   | version |      description       |
      | 145359 | 145359      | REOPENED | 1       | [SID] 15539 This is a fake bug!!!! | Research | Snort Rules | 2.6.0   | This is a fake bug!!!! |
    And I wait for "3" seconds
    When I goto "/bugs/145359"
    And I click ".attachments-tab"
    Then I should not see "Newpcap.pcap"
    And I click "#showAddAttachsToggle"
    And I fill in "new-attach-title" with "new.pcap"
    And I upload "Newpcap.pcap" from_button "file_data"
    When I click "Create Attachment"
    And I wait for "1" seconds
    And I click ".attachments-tab"
    Then I should see "Newpcap.pcap"
    Then I clean up attachments



  @javascript
  Scenario: a user can test an attachment
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state    | user_id | summary                            | product  | component   | version |      description       |
      | 145359 | 145359      | REOPENED | 1       | [SID] 15539 This is a fake bug!!!! | Research | Snort Rules | 2.6.0   | This is a fake bug!!!! |
    And an attachment exists and belongs to bug "145359"
    And I wait for "3" seconds
    When I goto "/bugs/145359"
    And I click ".jobs-tab"
    Then I should not see "attachment"
    And I click ".attachments-tab"
    And I toggle checkbox ".attach_1"
    Then I should see "new.pcap"
    When I click button "test"
    Then test should be created and I should see "Task has been created to test the attachment"
    And I click ".jobs-tab"
    Then I should see "attachment"

  @javascript
  Scenario: a user can edit research notes
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state    | user_id | summary                            | product  | component   | version |      description       |
      | 145359 | 145359      | REOPENED | 1       | [SID] 15539 This is a fake bug!!!! | Research | Snort Rules | 2.6.0   | This is a fake bug!!!! |
    Then I wait for "3" seconds
    And I goto "/bugs/145359"
    And I click ".notes-tab"
    And the textarea with id "researchNotesEditArea" should contain "THESIS: RESEARCH: DETECTION GUIDANCE: DETECTION BREAKDOWN: REFERENCES:"
    And I click "edit"
    And  I fill in "research_notes" with "This is a research note"
    And I click "save"
    Then I should see "Notes saved"
    Then I wait for "2" seconds
    When I click "publish"
    And I wait for "5" seconds
    Then I should see "Notes published to bugzilla"
    And I click "edit"
    And  I fill in "research_notes" with "This is a research note too"
    And I click "save"
    Then I should see "Notes saved"

  @javascript
  Scenario: a user can edit committer notes.
    Given a user with commit permission exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state    | user_id | summary                            | product  | component   | version |      description       |
      | 145359 | 145359      | REOPENED | 1       | [SID] 15539 This is a fake bug!!!! | Research | Snort Rules | 2.6.0   | This is a fake bug!!!! |
    Then I wait for "2" seconds
    And I goto "/bugs/145359"
    And I click ".notes-tab"
    And I click "Committer notes"
    Then I wait for "1" seconds
    And I click "#committerNotesEditBtn"
    And  I fill in "committer_notes" with "This is a research note"
    And I click "save"
    Then I should see "Notes saved"
    When I click "#committerNotesPublishBtn"
    And I wait for "3" seconds
    Then I should see "Notes published to bugzilla"
    And I click "#committerNotesEditBtn"
    And  I fill in "committer_notes" with "This is a research note too"
    And I click "save"
    Then I should see "Notes saved"


  @javascript
  Scenario: a user can add a comment
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state    | user_id | summary                            | product  | component   | version |      description       |
      | 145359 | 145359      | REOPENED | 1       | [SID] 15539 This is a fake bug!!!! | Research | Snort Rules | 2.6.0   | This is a fake bug!!!! |
    Then I wait for "3" seconds
    And I goto "/bugs/145359"
    And I click ".history-tab"
    And I click "#showAddNotesToggle"
    And  I fill in "noteCommentField" with "I love testing"
    And I click "save"
    And I wait for "2" seconds
    Then I should see "Comment saved and published to bugzilla"
    And I wait for "1" seconds
    Then I should see "I love testing"

  @javascript
  Scenario: a user can sort history from oldest to newest messages.
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state    | user_id | summary                            | product  | component   | version |      description       |
      | 145359 | 145359      | REOPENED | 1       | [SID] 15539 This is a fake bug!!!! | Research | Snort Rules | 2.6.0   | This is a fake bug!!!! |
    And the following notes exist:
      | id |   comment     |  note_type |        author       | bug_id  |
      | 1  |i like comments| "research" | "nicherbe@cisco.com"| 145359  |
      | 2  |pork sandwiches| "research" | "nicherbe@cisco.com"| 145359  |
    Then I wait for "3" seconds
    And I goto "/bugs/145359"
    And I click ".history-tab"
    Then note number "1" should say "i like comments"
    And note number "2" should say "pork sandwiches"
    When I click "#notesTLDRToggle"
    Then note number "1" should say "pork sandwiches"
    And note number "2" should say "i like comments"


