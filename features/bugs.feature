Feature: Bug
  In order to import, create or edit bugs
  as a user
  I will provides ways to interact with bugs

  @javascript
  Scenario: A user cannot import an empty string
    Given a user with role "analyst" exists and is logged in
    Then I wait for "3" seconds
    And  I goto "/bugs"
    Then I cannot click "button_import"

  # ==== Filter and Search Bugs ===

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
    And  I should see "Open Bugs"
    And  I should not see "fixed bug"
    And  I goto "/bugs?q=my-open-bugs"
    And  I should see "test summary"
    And  I should not see "No Tags in this one"
    And  I goto "/bugs?q=my-bugs"
    And  I should see "My Bugs"
    Then I should see "[[TELUS][VULN][BP] [SID] 22078 test summary"
    And  I should not see "No Tags in this one"
    Then I goto "/bugs?q=fixed-bugs"
    And  I should see "Fixed Bugs"
    And  I should see "[BP][NSS] fixed bug"
    And  I should not see "No Tags in this one"

  @javascript
  Scenario: The bug filter should reset when navigating
            from the users section to the bugs section
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | bugzilla_id | state | user_id | summary                                     | product  | component   | version | description       |
      | 111111      | OPEN  | 1       | [[TELUS][VULN][BP] [SID] 22078 test summary | Research | Snort Rules | 2.6.0   | test description  |
      | 222222      | OPEN  | 2       | No Tags in this one                         | Research | Snort Rules | 2.6.0   | test description2 |
      | 222222      | FIXED | 2       | [BP][NSS] fixed bug                         | Research | Snort Rules | 2.6.0   | test description3 |
    Then I wait for "3" seconds
    And  I goto "/bugs"
    And  I should see "Bugs"
    And  I should see "test summary"
    And  I goto "/bugs?q=open-bugs"
    Then I should see "No Tags in this one"
    And  I should see "Open Bugs"
    And  I should not see "fixed bug"
    And  I goto "/users"
    Then I goto "/bugs"
    And  I should see "test summary"
    And  I should not see "No Tags in this one"


  @javascript
  Scenario: A user can perform an advanced search on bugs
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id          | state | user_id | summary                                     | product  | component   | version | description       |
      | 111111      | OPEN  | 1       | [TELUS][VULN][BP] [SID] 22078 test summary  | Research | Snort Rules | 2.6.0   | test description  |
      | 222222      | OPEN  | 2       | No Tags in this one                         | Research | Snort Rules | 2.6.0   | test description2 |
      | 333333      | FIXED | 2       | [BP][NSS] fixed bug                         | Research | Snort Rules | 2.6.0   | test description3 |
    And the following tags exist:
      | name  | id |
      | TELUS | 1  |
      | VULN  | 2  |
      | BP    | 3  |
      | NSS   | 4  |
    And the following giblets exist:
      | bug_id          | name     | gib_type | gib_id   |
      | 111111          | TELUS    | Tag      | 1        |
      | 111111          | BP       | Tag      | 3        |
      | 111111          | VULN     | Tag      | 2        |
      | 333333          | BP       | Tag      | 3        |
      | 333333          | NSS      | Tag      | 4        |

    And the bug "111111" has tag "BP"
    And the bug "111111" has tag "TELUS"
    And the bug "111111" has tag "VULN"
    And the bug "333333" has tag "BP"
    And the bug "333333" has tag "NSS"
    Then I wait for "3" seconds
    And  I goto "/bugs"
    And  I should see "Bugs"
    And  I should see "test summary"
    When I click "search-bugs-btn"
    Then I wait for "3" seconds
    And  I fill in selectized with "BP"
    When I click "submit"
    Then I wait for "5" seconds
    And  I should see "test summary"
    And  I should see "fixed bug"
    And  I should not see "No Tags in this one"
    When I click "search-bugs-btn"
    Then I wait for "3" seconds
    And  I fill in selectized with "BP"
    And  I select "FIXED" from "bug[state]"
    When I click "submit"
    Then I wait for "5" seconds
    And  I should see "fixed bug"
    And I should not see "test summary"

  @javascript
  Scenario: A user can perform an advanced search on bugs and save results
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id          | state | user_id | summary                                     | product  | component   | version | description       |
      | 111111      | OPEN  | 1       | [TELUS][VULN][BP] [SID] 22078 test summary  | Research | Snort Rules | 2.6.0   | test description  |
      | 222222      | OPEN  | 2       | No Tags in this one                         | Research | Snort Rules | 2.6.0   | test description2 |
      | 333333      | FIXED | 2       | [BP][NSS] fixed bug                         | Research | Snort Rules | 2.6.0   | test description3 |
    And the following tags exist:
      | name  | id |
      | TELUS | 1  |
      | VULN  | 2  |
      | BP    | 3  |
      | NSS   | 4  |
    And the following giblets exist:
      | bug_id          | name     | gib_type | gib_id   |
      | 111111          | TELUS    | Tag      | 1        |
      | 111111          | BP       | Tag      | 3        |
      | 111111          | VULN     | Tag      | 2        |
      | 333333          | BP       | Tag      | 3        |
      | 333333          | NSS      | Tag      | 4        |

    And the bug "111111" has tag "BP"
    And the bug "111111" has tag "TELUS"
    And the bug "111111" has tag "VULN"
    And the bug "333333" has tag "BP"
    And the bug "333333" has tag "NSS"
    Then I wait for "3" seconds
    And  I goto "/bugs"
    And  I should see "Bugs"
    And  I should see "test summary"
    When I click "search-bugs-btn"
    Then I wait for "3" seconds
    And  I fill in selectized with "BP"
    And  I fill in "bug[saved_search]" with "saved search test"
    When I click "submit"
    Then I wait for "5" seconds
    And  I should see "test summary"
    And  I should see "fixed bug"
    And  I should not see "No Tags in this one"
    And  I should have 1 saved searches for user 1

  @javascript
  Scenario: A user can perform an advanced search using a saved search
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id          | state | user_id | summary                                     | product  | component   | version | description       |
      | 111111      | OPEN  | 1       | [TELUS][VULN][BP] [SID] 22078 test summary  | Research | Snort Rules | 2.6.0   | test description  |
      | 222222      | OPEN  | 2       | No Tags in this one                         | Research | Snort Rules | 2.6.0   | test description2 |
      | 333333      | FIXED | 2       | [BP][NSS] fixed bug                         | Research | Snort Rules | 2.6.0   | test description3 |
    And the following tags exist:
      | name  | id |
      | TELUS | 1  |
      | VULN  | 2  |
      | BP    | 3  |
      | NSS   | 4  |
    And the following giblets exist:
      | bug_id          | name     | gib_type | gib_id   |
      | 111111          | TELUS    | Tag      | 1        |
      | 111111          | BP       | Tag      | 3        |
      | 111111          | VULN     | Tag      | 2        |
      | 333333          | BP       | Tag      | 3        |
      | 333333          | NSS      | Tag      | 4        |

    And the bug "111111" has tag "BP"
    And the bug "111111" has tag "TELUS"
    And the bug "111111" has tag "VULN"
    And the bug "333333" has tag "BP"
    And the bug "333333" has tag "NSS"
    Then I wait for "3" seconds
    And  I goto "/bugs"
    And  I should see "Bugs"
    And  I should see "test summary"
    When I click "search-bugs-btn"
    Then I wait for "3" seconds
    And  I fill in selectized with "BP"
    And  I fill in "bug[saved_search]" with "saved search test"
    When I click "submit"
    Then I wait for "5" seconds
    And  I should see "test summary"
    And  I should see "fixed bug"
    And  I should not see "No Tags in this one"
    And  I should have 1 saved searches for user 1
    Then I click "search-bugs-btn"
    Then I click "nav-saved-search-tab"
    And  I should see "saved search test"
    When I click link "saved search test"
    Then I wait for "5" seconds
    And I should see "test summary"
    And  I should see "fixed bug"
    And  I should not see "No Tags in this one"

  @javascript
  Scenario: A user will see a warning message if bug looks to be
            out of synch with bugzilla (probably from a light import).
            Out of synch is based on presence of notes on the bug.
    Given a user with role "analyst" exists and is logged in
    And the following users exist
      | id | email                         | cvs_username  | display_name        |
      | 2  | vrt-incoming@sourcefire.com   | vrt_incoming  | Rainbow Brite       |

    And the following bugs exist:
      | id          | state | user_id | summary                                     | product  | component   | version | description       |
      | 111111      | OPEN  | 1       | [[TELUS][VULN][BP] [SID] 22078 test summary | Research | Snort Rules | 2.6.0   | test description  |
      | 222222      | OPEN  | 2       | No Tags in this one                         | Research | Snort Rules | 2.6.0   | test description2 |
      | 333333      | FIXED | 2       | [BP][NSS] fixed bug                         | Research | Snort Rules | 2.6.0   | test description3 |

    And the following notes exist:
      | id |   comment     |  note_type |        author       | bug_id  |
      | 1  |i like comments| "research" | "nicherbe@cisco.com"| 222222  |
      | 2  |pork sandwiches| "research" | "nicherbe@cisco.com"| 222222  |

    Then I wait for "3" seconds
    And  I goto "/bugs/222222"

    And  I should not see "Looks like this bug(222222) may be out of sink"
    Then I goto "/bugs/111111"
    And  I should see "Looks like this bug (111111) may be out of sink"


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
    And  I fill in "bug[summary]" with "New Bug Summary"
    And  I fill in "bug[description]" with "This is my description."
    And  I fill in "bug[whiteboard]" with "TELUS"
#    Then I click "Save"
#    Then I wait for "3" seconds
#    Then take a photo

#    Then I should see "[TELUS]New Bug Summary"
#    And  the selectize field contains the text "TELUS"
  # need connection to bugzilla for testing the above


  @javascript
  Scenario: After a new bug is created,
  the description should appear as the first item in the history
    Given a user with role "analyst" exists and is logged in
    Then I wait for "3" seconds
    And  I goto "/bugs/new"
    And  I fill in "bug[summary]" with "New Bug Summary"
    And  I fill in "bug[description]" with "This is my description."
#    Then I click "Save"
#    Then I wait for "3" seconds
#    Then I should see "New Bug Summary"
#    And I click ".history-tab"
# And I should see "This is my description"
# need connection to bugzilla for testing the above



  # ==== Editing Tags ===
  @javascript
  Scenario: The summary text should update with tag edits
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state  | user_id | summary                       | product  | component   | version | description       |
      | 153354 | 153354      | FIXED  | 1       | [BP][NSS] Fake bug the second | Research | Snort Rules | 2.6.0   | test description3 |
    Then I wait for "3" seconds
    And I goto "/bugs/153354"
    Then I should see "[BP][NSS] Fake bug the second"
    And  I fill in selectized with "TELUS"
    Then the selectize field with id "whiteboard-select-to-edit" contains the text "TELUS"


  # ==== Deleting Bugs ===
  @javascript
  Scenario: A bug can be deleted
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
    Then I wait for "3" seconds
    And I goto "/bugs?q=my-bugs"
    Then I should see "[BP][NSS] fixed bug"
    And I wait for "1" seconds
    When I click "delete_bug222222"
    And I wait for "1" seconds
    And I goto "/bugs"
    Then I should not see "[BP][NSS] fixed bug"


  # ==== Importing a Bug ===
  @javascript
  Scenario: A bug can be imported
#    Given a user with role "analyst" exists and is logged in
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
  Scenario: a user can take a bug
    Given a user with role "analyst" exists and is logged in
    And the following users exist
      | id | email                         | cvs_username  | display_name        |
      | 2  | vrt-incoming@sourcefire.com   | vrt_incoming  | Rainbow Brite       |
    And the following bugs exist:
      | bugzilla_id | state | user_id | summary                                     | product  | component   | version | description       |
      | 111111      | OPEN  | 2       | [[TELUS][VULN][BP] [SID] 22078 test summary | Research | Snort Rules | 2.6.0   | test description  |
    Then I wait for "3" seconds
    And  I goto "/bugs?q=open-bugs"
    Then I should see "take"
    And I should see "vrt_incoming"
    When I click "take"
    And I wait for "5" seconds
# uncomment when connectivity to bugzilla test fixed
#    Then I should not see "vrt_incoming"
#    And I should see "nherbert"
#    And I should see "return"


  @javascript
  Scenario: a user can return a bug
    Given a user with role "analyst" exists and is logged in
    And the following users exist
      | id | email                         | cvs_username  | display_name        |
      | 2  | vrt-incoming@sourcefire.com   | vrt_incoming  | Rainbow Brite       |
    And the following bugs exist:
      | bugzilla_id | state | user_id | summary                                     | product  | component   | version | description       |
      | 111111      | OPEN  | 1       | [[TELUS][VULN][BP] [SID] 22078 test summary | Research | Snort Rules | 2.6.0   | test description  |

    Then I wait for "3" seconds
    When I goto "/bugs?q=open-bugs"
    Then I should see "return"
    And I should see my username
    When I click "return"
    And I wait for "5" seconds
# uncomment when connectivity to bugzilla test fixed
#    Then I should not see "nherbert"
#    And I should see "vrt_incoming"
#    And I should see "take"


  @javascript
  Scenario: a user can set the state of a bug to pending
    Given a user with role "analyst" exists and is logged in
    And the following reference types exist:
      | id | name    | description  | example |
      | 1  | cve     | just a thing | 222-222 |
      | 2  | url     | just a thing | 222-222 |
      | 3  | bugtraq | just a thing | 222-222 |
      | 4  | telus   | just a thing | 222-222 |
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       | committer_id |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |     1        |
    And the following rule categories exist:
      | category      | id |
      | BLACKLIST     |  1 |
      | FILE-IDENTIFY |  2 |
    And the following "synched_rule" rules exist belonging to bug "222222":
      |id | message               | rule_category_id | parsed |
      |1  | FILE-IDENTIFY message | 2                |  true  |
    And the following references exist:
      | id | reference_data | reference_type_id |
      | 1  | 2006-5745      | 1                 |
    And rule with id "1" has a reference with id "1"
    And I wait for "2" seconds
    And I goto "/bugs/222222"
    When I click the span with data-target "#editBug"
    And I wait for "1" seconds
    Then I select "PENDING" from "bug[state]"

#  @now
#  @wip
#  @javascript
#  Scenario: a bug can be set to pending
#    Given a user with role "analyst" exists and is logged in
#    And the following exploit types exist:
#      | id | name   | description                              |
#      | 1  | core   | Core Impact exploit module.              |
#      | 2  | telus  | Other publicly available exploit module. |
#      | 3  | canvas | Immunity Canvas exploit module.          |
#    And the following reference types exist:
#      | id | name    | description  | example |
#      | 1  | cve     | just a thing | 222-222 |
#      | 2  | url     | just a thing | 222-222 |
#      | 3  | bugtraq | just a thing | 222-222 |
#      | 4  | telus   | just a thing | 222-222 |
#    And the following bugs exist:
#      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       | committer_id |
#      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |     1        |
#    And the following rule categories exist:
#      | category  | id |
#      | BLACKLIST |  1 |
#    And the following rules exist belonging to bug "222222":
#      |id | message                 | rule_category_id | parsed |
#      |1  | BLACKLIST message       | 1                |  true  |
#    And the following references exist:
#      | id | reference_data | reference_type_id |
#      | 1  | 2006-5745      | 1                 |
#    And rule with id "1" has a reference with id "1"
#    Then I wait for "2" seconds
#    And I goto "/bugs/222222"
#    Then I do some debugging

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
      | 4  | telus   | just a thing | 222-222 |
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       | committer_id |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |     1        |
    And the following rule categories exist:
      | category  | id |
      | BLACKLIST |  1 |
    And the following "synched_rule" rules exist belonging to bug "222222":
      |id | message                 | rule_category_id | parsed |
      |1  | BLACKLIST message       | 1                |  true  |
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
    Then I click the span with data-target "#editBug"
    And I wait for "1" seconds
    Then I should see "Can't set to pending. Please complete the summary for rule docs."
    And I can not select "PENDING" from "bug[state]"

  @javascript
  Scenario: a user can not set the state of a bug to pending when rule doc summaries are missing
    Given a user with role "analyst" exists and is logged in
    And the following reference types exist:
      | id | name    | description  | example |
      | 1  | cve     | just a thing | 222-222 |
      | 2  | url     | just a thing | 222-222 |
      | 3  | bugtraq | just a thing | 222-222 |
      | 4  | telus   | just a thing | 222-222 |
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       | committer_id |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |     1        |
    And the following rule categories exist:
      | category  | id |
      | BLACKLIST |  1 |
    And the following "synched_rule" rules exist belonging to bug "222222":
      |id | message                 | rule_category_id | parsed |
      |1  | BLACKLIST message       | 1                |  true  |
    And the following references exist:
      | id | reference_data | reference_type_id |
      | 1  | 2006-5745      | 1                 |
    And rule with id "1" has a reference with id "1"
    Then I wait for "2" seconds
    And I goto "/bugs/222222"
    Then I click the span with data-target "#editBug"
    And I wait for "1" seconds
    Then I should see "Can't set to pending."
    And I can not select "PENDING" from "bug[state]"

  @javascript
  Scenario: a user can set the state of a bug to pending when deleted rule doc summaries are missing
    Given a user with role "analyst" exists and is logged in
    And the following reference types exist:
      | id | name    | description  | example |
      | 1  | cve     | just a thing | 222-222 |
      | 2  | url     | just a thing | 222-222 |
      | 3  | bugtraq | just a thing | 222-222 |
      | 4  | telus   | just a thing | 222-222 |
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       | committer_id |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |     1        |
    And the following rule categories exist:
      | category  | id |
      | DELETED   |  1 |
    And the following "synched_rule" rules exist belonging to bug "222222":
      |id | message                 | rule_category_id | parsed |
      |1  | BLACKLIST message       | 1                |  true  |
    And the following references exist:
      | id | reference_data | reference_type_id |
      | 1  | 2006-5745      | 1                 |
    And rule with id "1" has a reference with id "1"
    Then I wait for "2" seconds
    And I goto "/bugs/222222"
    Then I click the span with data-target "#editBug"
    And I wait for "1" seconds
    Then I select "PENDING" from "bug[state]"

  @javascript
  Scenario: a user can set the state of a bug to pending when file-identify rule doc summaries are missing
    Given a user with role "analyst" exists and is logged in
    And the following reference types exist:
      | id | name    | description  | example |
      | 1  | cve     | just a thing | 222-222 |
      | 2  | url     | just a thing | 222-222 |
      | 3  | bugtraq | just a thing | 222-222 |
      | 4  | telus   | just a thing | 222-222 |
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       | committer_id |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |     1        |
    And the following rule categories exist:
      | category      | id |
      | FILE-IDENTIFY |  1 |
    And the following "synched_rule" rules exist belonging to bug "222222":
      |id | message                 | rule_category_id | parsed |
      |1  | BLACKLIST message       | 1                |  true  |
    And the following references exist:
      | id | reference_data | reference_type_id |
      | 1  | 2006-5745      | 1                 |
    And rule with id "1" has a reference with id "1"
    Then I wait for "2" seconds
    And I goto "/bugs/222222"
    Then I click the span with data-target "#editBug"
    And I wait for "1" seconds
    Then I select "PENDING" from "bug[state]"

  @javascript
  Scenario: a user can not set the state of a bug to pending when a rule does not parse
    Given a user with role "analyst" exists and is logged in
    And the following reference types exist:
      | id | name    | description  | example |
      | 1  | cve     | just a thing | 222-222 |
      | 2  | url     | just a thing | 222-222 |
      | 3  | bugtraq | just a thing | 222-222 |
      | 4  | telus   | just a thing | 222-222 |
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       | committer_id |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |     1        |
    And the following rule categories exist:
      | category      | id |
      | APP-DETECT    |  1 |
      | FILE-IDENTIFY |  2 |
    And the following "edited_rule" rules exist belonging to bug "222222":
      |id | message               | rule_category_id | parsed |
      |1  | FILE-IDENTIFY message | 2                | false  |
    And the following references exist:
      | id | reference_data | reference_type_id |
      | 1  | 2006-5745      | 1                 |
    And rule with id "1" has a reference with id "1"
    And I wait for "2" seconds
    And I goto "/bugs/222222"
    When I click the span with data-target "#editBug"
    And I wait for "2" seconds
    Then I should see "Can't set to pending."
    And I can not select "PENDING" from "bug[state]"

  @javascript
  Scenario: a user can add a comment when manually changing the state of a bug
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       | committer_id |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |     1        |
    Then I wait for "2" seconds
    And I goto "/bugs/222222"
    Then I click the span with data-target "#editBug"
    And I wait for "1" seconds
    Then I should not see "State Comment"
    Then I select "ASSIGNED" from "bug[state]"
    Then I should see "State Comment"


  @javascript
  Scenario: a user can not set the state of a bug to fixed, wontfix, later or invalid if they aren't a committer
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state     | user_id | summary             | product  | component   | version | description       | committer_id |
      | 222222 | 222222      | ASSIGNED  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |     1        |
    Then I wait for "2" seconds
    And I goto "/bugs/222222"
    Then I click the span with data-target "#editBug"
    And I wait for "1" seconds
    And the "FIXED" option from "bug[state]" is disabled
    And the "REOPENED" option from "bug[state]" is not disabled

  @javascript
  Scenario: a user can set the state of a bug to fixed, wontfix, later or invalid if they are a committer
    Given a user with role "committer" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state     | user_id | summary             | product  | component   | version | description       | committer_id |
      | 222222 | 222222      | ASSIGNED  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |     1        |
    Then I wait for "2" seconds
    And I goto "/bugs/222222"
    Then I click the span with data-target "#editBug"
    And I wait for "1" seconds
    And the "FIXED" option from "bug[state]" is not disabled
    And the "REOPENED" option from "bug[state]" is not disabled


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
      | id | email                | cvs_username  | display_name        | parent_id | cec_username |
      | 2  | rainbows@email.com   | rainbow_b     | Rainbow Brite       | 1         | rainbow_b    |
      | 3  | hclinton@email.com   | h_clinton     | Hillary Clinton     | 2         | h_clinton    |
      | 4  | dtrump@email.com     | d_drumph      | Donald Trump        | 1         | d_drumph     |
      | 5  | gjohns@email.com     | g_johnson     | Gary Johnson        |           | g_johnson    |
      | 6  | tbeary@email.com     | t_bear        | Teddy Bear          | 2         | t_bear       |

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
    Then I click the span with data-target "#editBug"
    And I wait for "1" seconds
    And "rainbow_b" should be in the "bug[user_id]" dropdown list
    And "t_bear" should not be in the "bug[user_id]" dropdown list
    And I select "rainbow_b" from "bug[user_id]"
    Then I click button "Save"
    And I wait for "3" seconds
# uncomment when connectivity to bugzilla test fixed
# And I should see "rainbow_b"

  @javascript
  Scenario: a user can change the committer of a bug
            only a user with role committer should be available in the dropdown
            user assigned as editor cannot be in the committer dropdown
    Given a user with role "analyst" exists and is logged in

    And the following users exist
      | id | email                | cvs_username  | display_name        | parent_id | cec_username |
      | 2  | rainbows@email.com   | rainbow_b     | Rainbow Brite       | 1         | rainbow_b    |
      | 3  | hclinton@email.com   | h_clinton     | Hillary Clinton     | 2         | h_clinton    |
      | 4  | dtrump@email.com     | d_drumph      | Donald Trump        | 1         | d_drumph     |
      | 5  | gjohns@email.com     | g_johnson     | Gary Johnson        |           | g_johnson    |
      | 6  | tbeary@email.com     | t_bear        | Teddy Bear          | 2         | t_bear       |

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
    Then I click the span with data-target "#editBug"
    And I wait for "1" seconds
    And "t_bear" should be in the "bug[committer_id]" dropdown list
    And "d_drumph" should not be in the "bug[committer_id]" dropdown list
    And I select "t_bear" from "bug[committer_id]"
    Then I click button "Save"
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
    Then I click the span with data-target "#editBug"
    And I wait for "1" seconds
    And I select "P2" from "bug[priority]"
#    Then I click button "Save"
#    And I wait for "3" seconds
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
    Then I click the span with data-target "#editBug"
    And I wait for "1" seconds
    And I select "Malware" from "bug[component]"
#    Then I click button "Save"
#    And I wait for "3" seconds
# uncomment when connectivity to bugzilla test fixed
#    Then I should see "Malware"

  @javascript
  Scenario: a user can change the classification of a bug
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
    Then I wait for "3" seconds
    And I goto "/bugs/222222"
    Then I click the span with data-target "#editBug"
    And I wait for "1" seconds
    And I select "Secret" from "bug[classification]"
#    Then I click button "Save"
#    And I wait for "3" seconds
# uncomment when connectivity to bugzilla test fixed
#    Then I should see "Secret"

  @javascript
  Scenario: a user can change the summary of a bug
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
    Then I wait for "3" seconds
    And I goto "/bugs/222222"
    Then I click the span with data-target "#editBug"
    And I wait for "1" seconds
    And I fill in "bug[summary]" with "new summary"
#    Then I click button "Save"
# uncomment when connectivity to bugzilla test fixed
# Then I should see "new summary"

# uncomment when connectivity to bugzilla test fixed
#  @javascript
#  Scenario: a bug's rules that listed in the summary should have the in_summary flag set on bugs_rules
#    Given a user with role "analyst" exists and is logged in
#    And the following bugs exist:
#      | id     | bugzilla_id | state | user_id | summary                         | product  | component   | version | description       | committer_id |
#      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |     1        |
#    And the following rule categories exist:
#      | category  | id |
#      | BLACKLIST |  1 |
#    And the following "synched_rule" rules exist belonging to bug "222222":
#      |id | message                  | rule_category_id | parsed | sid   |
#      |1  | BLACKLIST message        | 1                |  true  | 19500 |
#      |2  | BLACKLIST message  2     | 1                |  true  | 19501 |
#    Then I wait for "2" seconds
#    And I goto "/bugs/222222"
#    Then I click the span with data-target "#editBug"
#    And I wait for "1" seconds
#    And I fill in "bug[summary]" with "[SID] 19500 fixed bug"
#    Then I click "Save"
#    Then I wait for "5" seconds
#    And bugs_rules with rule_id of "1" and "bug_id" of "222222" should have the in_summary flag
#    And bugs_rules with rule_id of "2" and "bug_id" of "222222" should not have the in_summary flag



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
    And the following rule categories exist:
      | category  | id |
      | BLACKLIST |  1 |
    And the following "synched_rule" rules exist belonging to bug "222222":
      | message                 | rule_category_id |
      | BLACKLIST message       | 1                |
    Then I wait for "3" seconds
    And I goto "/bugs/222222"
    And I click ".rules-tab"

  @javascript
  Scenario: a user can test a rule
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state    | user_id | summary                            | product  | component   | version |      description       |
      | 145359 | 145359      | REOPENED | 1       | [SID] 15539 This is a fake bug!!!! | Research | Snort Rules | 2.6.0   | This is a fake bug!!!! |
    And the following rule categories exist:
      | category  | id |
      | BLACKLIST |  1 |
    And the following "synched_rule" rules exist belonging to bug "145359":
      |  id  | message                 | rule_category_id |
      | 3591 | BLACKLIST message       | 1                |
    And an attachment exists and belongs to bug "145359"
    And I wait for "3" seconds
    When I goto "/bugs/145359"
    And I click ".jobs-tab"
    Then I should not see "local test"
    When I click ".rules-tab"
    And I toggle checkbox ".rule_3591"
    And I click button "test"
    Then test should be created and I should see "Task has been created to test the rule"
    When I click ".jobs-tab"
    Then I should see "local test"

  @javascript
  Scenario: a user can add an attachment
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state    | user_id | summary                            | product  | component   | version |      description       |
      | 145359 | 145359      | REOPENED | 1       | [SID] 15539 This is a fake bug!!!! | Research | Snort Rules | 2.6.0   | This is a fake bug!!!! |
    And I wait for "3" seconds
    When I goto "/bugs/145359"
    And I click ".attachments-tab"
    Then I should not see "Newpcap.pcap"
    And I click "#showAddAttachsToggle"
    And I upload "Newpcap.pcap" from_button "file_data"
    When I click "Create Attachment"
    And I wait for "1" seconds
    And I click ".attachments-tab"
    Then I should see "Newpcap.pcap"
    And the attachment with file name "Newpcap.pcap" summary should be saved as "Newpcap.pcap"
    Then I clean up attachments
    
  @javascript
  Scenario: attachments should be tested after importing a bug
    Given a user with role "analyst" exists and is logged in
    And a reference type exists
    And I wait for "3" seconds
    When I goto "/bugs"
    And I fill in "bug_name" with "145359"
    And I click "#button_import"
    And I wait for "10" seconds
    Then I goto "/bugs/145359"
    #then you should see the bug but this doesnt happen because there is no easy way to test the import feature
    #When I click ".jobs-tab"
    #Then I should see "attachment"

  @javascript
  Scenario: a user can test an attachment
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state    | user_id | summary                                                    | product  | component   | version |      description       |
      | 111116 | 111116      | REOPENED | 1       | [SID] 24397 Steam browser handler multiple vulnerabilities | Research | Snort Rules | 2.6.0   | This is a fake bug!!!! |
    And an attachment exists and belongs to bug "111116"
    And I wait for "3" seconds
    When I goto "/bugs/111116"
    And I click ".jobs-tab"
    Then I should not see "all rules test"
    When I click ".attachments-tab"
    And I toggle checkbox ".attach_1"
    Then I should see "new.pcap"
    When I click button "test"
    Then test should be created and I should see "Task has been created to test the attachment"
    When I click ".jobs-tab"
    Then I should see "all rules test"

  @javascript
  Scenario: a user can edit research notes
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state    | user_id | summary                            | product  | component   | version |      description       |
      | 145359 | 145359      | REOPENED | 1       | [SID] 15539 This is a fake bug!!!! | Research | Snort Rules | 2.6.0   | This is a fake bug!!!! |
    Then I wait for "3" seconds
    And I goto "/bugs/145359"
    And I click ".notes-tab"
    Then the textarea with id "researchNotesEditArea" should contain "THESIS: RESEARCH: DETECTION GUIDANCE: DETECTION BREAKDOWN: REFERENCES:"
    And I click "researchNotesEditBtn"
    And  I fill in "research_notes" with "This is a research note"
    And I click "researchNotesSaveBtn"
    Then I should see "Notes saved"
    Then I wait for "2" seconds
    And I click "researchNotesEditBtn"
    And  I fill in "research_notes" with "This is a research note too"
    And I click "researchNotesSaveBtn"
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
    And I goto "/bugs/145359"
    And I click ".notes-tab"
    And I click "Committer notes"
    Then I wait for "1" seconds
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
    Then I should see "Note Published"
    And I wait for "10" seconds
    Then I should see "I love testing"

@javascript
  Scenario: a user can sort history from oldest to newest messages.
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state    | user_id | summary                            | product  | component   | version |      description       |
      | 145359 | 145359      | REOPENED | 1       | [SID] 15539 This is a fake bug!!!! | Research | Snort Rules | 2.6.0   | This is a fake bug!!!! |
    And the following notes exist:
      | id |   comment     |  note_type |        author       | bug_id  | notes_bugzilla_id |
      | 1  |i like comments| "research" | "nicherbe@cisco.com"| 145359  |   1927402          |
      | 2  |pork sandwiches| "research" | "nicherbe@cisco.com"| 145359  |   1720346          |
    Then I wait for "3" seconds
    And I goto "/bugs/145359"
    And I click ".history-tab"
    Then note number "1" should say "i like comments"
    And note number "2" should say "pork sandwiches"
    When I click "#notesTLDRToggle"
    Then note number "1" should say "pork sandwiches"
    And note number "2" should say "i like comments"

  @javascript
  Scenario: a bug that has a reference in the bug summary should display that reference in the overview tab
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state    | user_id | summary                                          | product  | component   | version |      description       |
      | 145359 | 145359      | REOPENED | 1       | [SID] 15539 CVE-2008-1434 This is a fake bug!!!! | Research | Snort Rules | 2.6.0   | This is a fake bug!!!! |
    And the following reference types exist:
      | id | name    | description  | example |
      | 1  | cve     | just a thing | 222-222 |
      | 2  | url     | just a thing | 222-222 |
      | 3  | bugtraq | just a thing | 222-222 |
      | 4  | telus   | just a thing | 222-222 |
    And the following references exist belonging to bug "145359":
      | id | reference_data | reference_type_id |
      | 1  | 2008-1434      | 1                 |
    Then I wait for "3" seconds
    And I goto "/bugs/145359"
    And I click ".overview"
    Then I should see "2008-1434"

  @javascript
  Scenario: a bug that has a rule with a reference should display that rule reference in the overview tab
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state    | user_id | summary                                          | product  | component   | version |      description       |
      | 145359 | 145359      | REOPENED | 1       | [SID] 15539 This is a fake bug!!!! | Research | Snort Rules | 2.6.0   | This is a fake bug!!!! |
    And the following rule categories exist:
      | category  | id |
      | DELETED   |  1 |
    And the following reference types exist:
      | id | name    | description  | example |
      | 1  | cve     | just a thing | 222-222 |
      | 2  | url     | just a thing | 222-222 |
      | 3  | bugtraq | just a thing | 222-222 |
      | 4  | telus   | just a thing | 222-222 |
    And the following "synched_rule" rules exist belonging to bug "145359":
      |id | message                 | rule_category_id | parsed | sid  |
      |1  | BLACKLIST message       | 1                |  true  | 19001|
    And the following references exist belonging to rule with sid "19001":
      | id | reference_data | reference_type_id |
      | 1  | 2006-5745      | 1                 |
    Then I wait for "3" seconds
    And I goto "/bugs/145359"
    And I click ".overview"
    Then I should see "2006-5745"


  @javascript
  Scenario: a bug that has attachments with alerts should provide a link to the rule view
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state    | user_id | summary                                          | product  | component   | version |      description       |
      | 145359 | 145359      | REOPENED | 1       | [SID] 15539 CVE-2008-1434 This is a fake bug!!!! | Research | Snort Rules | 2.6.0   | This is a fake bug!!!! |
    And the following "synched_rule" rules exist belonging to bug "145359":
      |id | message                 | rule_category_id | parsed | sid  |
      |1  | BLACKLIST message       | 1                |  true  | 19001|
    And an attachment exists that belongs to bug "145359" and alerts on rule "1"
    And  I goto "/bugs/145359"
    And  I click ".alerts-tab"
    Then I should see "All Rules"
    When I click "#rule-link"
    Then I should see "alert tcp $EXTERNAL_NET $FILE_DATA_PORTS -> $HOME_NET any"
    And  I should not see "All Rules"


  @javascript
  Scenario: A user can search by specific bug ID and is taken to that ID if a single match exists
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state    | user_id | summary                                          | product  | component   | version |      description            |
      | 35487  | 35487       | REOPENED | 1       | [SID] 15531 CVE-2017-1434 Totally fake data      | Research | Snort Rules | 2.6.0   | None of this really matters |
      | 135487 | 135487      | OPEN     | 1       | [[TELUS][VULN][BP] [SID] 135487 test summary     | Research | Snort Rules | 2.6.0   | some other helpful value    |
      | 354873 | 354873      | OPEN     | 1       | [[TELUS][VULN][BP] [SID] 354873 test summary     | Research | Snort Rules | 2.6.0   | some other helpful value    |
      | 354875 | 354875      | OPEN     | 1       | [SID] 15539 CVE-2008-1434 This is a fake bug!!!! | Research | Snort Rules | 2.6.0   | This is a fake bug!!!!      |
    And  I wait for "3" seconds
    And  I goto "/bugs"
    When I search for bug id "35487"
    And  I wait for "10" seconds
    Then I should see "35487"
    And  I should not see "135487"
    And  I should not see "354873"
    And  I should not see "354875"
    And  I should not see "Zarro Boogs found, please try selecting any other filter."

  @javascript
  Scenario: Notes are published when an analyst sets a bug to pending
    Given a user with role "analyst" exists and is logged in
    And  I goto "/bugs/new"
    And  I fill in "bug[summary]" with "New Bug Summary"
    And  I fill in "bug[description]" with "This is my description."
    When I click button "Save"
    And  I wait for "10" seconds
    When I click ".history-tab"
    Then I should not see "THESIS:"
    Then I click "Resolve"
    And  I wait for "10" seconds
    And  I click "Resink Bug Now"
    And  I wait for "10" seconds
    When I click "Resolve"
    And  I wait for "10" seconds
    And  I click ".history-tab"
    Then I should see "THESIS:"

  @javascript
  Scenario: Add a comment from the history tab
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id |
      | 145359 | 145359      |
    When I goto "/bugs/145359"
    And  I click the "History" tab
    And  I click "add-notes-toggle-button"
    And  I fill in "noteCommentField" with "note from history tab"
    And  I click "submit_comment"
    Then pending

