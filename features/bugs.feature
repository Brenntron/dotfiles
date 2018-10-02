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
    And  I fill in "bug-form-summary-input" with "New Bug Summary"
    And  I fill in "bug-form-desc-input" with "This is my description."
    And  I fill in "bug-form-whiteboard-input" with "TELUS"
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
    And  I fill in "bug-form-summary-input" with "New Bug Summary"
    And  I fill in "bug-form-desc-input" with "This is my description."
#    Then I click "Save"
#    Then I wait for "3" seconds
#    Then I should see "New Bug Summary"
#    And I click ".history-tab"
# And I should see "This is my description"
# need connection to bugzilla for testing the above



