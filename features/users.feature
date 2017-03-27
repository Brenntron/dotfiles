Feature: User Accounts
  In order to provide account services
  As a user
  I want to provide user authentication

  ### Scenarios login ###

  @javascript
  Scenario: A user with proper credentials should get logged in
            and redirected to their user page
    Given current user exists
    And I visit the root url
    And I should see "Please wait while we sign you in"
    Then I wait for "3" seconds
    And I should not see "Please wait while we sign you in"
    And I should see "/users/1" in the current url

  @javascript
  Scenario: A user logging in not in the database should be added to the database
    Given current user not in database
    When I visit the root url
    Then I should see "Please wait while we sign you in"
    When I wait for "3" seconds
    Then I should not see "Please wait while we sign you in"
    And  current user should be in database

  @javascript
  Scenario: A user logging in, in the database for a bug, should have the kerberos login updated
    Given current user is a bug user
    Then current user should be in database
    When I visit the root url
    Then I should see "Please wait while we sign you in"
    When I wait for "3" seconds
    Then I should not see "Please wait while we sign you in"
    And  current user should be in database
    And  current user should have kerberos login


  ### Scenarios User management ###

  @javascript
  Scenario: A regular user should see a not found flash message
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id      | bugzilla_id | state  | user_id | summary             | product | component   | version | description       |
      |333333   | 333333      | OPEN   | 1       | [TELUS] broken bug  | Research| Snort Rules | 2.6.0   | test description4 |
    Given I wait for "3" seconds
    When I goto "/users/1001"
    Then I should see could not find user "1001" flash massage
    When I goto "/users/malformed"
    Then I should see could not find user "malformed" flash massage

  @javascript
  Scenario: A non-manager user can go to the users index page and see only their co-workers.
            Assigned bugs should be on users show page.
            A non-manager cannot get to the relationships section.
    Given a user with role "analyst" exists and is logged in
    And the following users exist
      | id | email                      | cvs_username | display_name        | parent_id |
      | 2  | rainbows@email.com         | rainbow_b    | Rainbow Brite       |           |
      | 3  | hclinton@email.com         | h_clinton    | Hillary Clinton     |  2        |
      | 4  | dtrump@email.com           | d_drumph     | Donald Trump        |           |

    And a user with id "1" has a parent with id "2"

    And the following bugs exist:
      | id      | bugzilla_id | state  | user_id | summary             | product | component   | version | description       |
      |222222   | 222222      | OPEN   | 3       | [BP][NSS] fixed bug | Research| Snort Rules | 2.6.0   | test description3 |
      |333333   | 333333      | OPEN   | 1       | [TELUS] broken bug  | Research| Snort Rules | 2.6.0   | test description4 |

    Then I wait for "3" seconds
    And  I goto "/users"
    And  I should see "h_clinton"
    And  I should not see "d_drumph"
    And  I should see a user search form
    Then I click "h_clinton"
    And  I should see "[BP][NSS] fixed bug"
    And  I should not see "[TELUS] broken bug"
    Then I goto "/users/4"
    And  I should see "You are not authorized to view that user."
    Then I goto "/users/1"
    And  I should see "[TELUS] broken bug"
    And  I goto "/users/1/relationships"
    And  I should see "You must be a manager to access that page."

  @javascript
  Scenario: A non-manager non-admin user cannot edit the role for any user.
    Given a user with role "analyst" exists and is logged in
    And the following users exist
      | id | email                | cvs_username | display_name        | parent_id |
      | 2  | rainbows@email.com   | rainbow_b    | Rainbow Brite       |           |
      | 3  | hclinton@email.com   | h_clinton    | Hillary Clinton     |     2     |
      | 4  | dtrump@email.com     | d_drumph     | Donald Trump        |           |

    And the following bugs exist:
      | id      | bugzilla_id | state  | user_id | summary             | product | component   | version | description       |
      |222222   | 222222      | OPEN   | 3       | [BP][NSS] fixed bug | Research| Snort Rules | 2.6.0   | test description3 |
      |333333   | 333333      | OPEN   | 1       | [TELUS] broken bug  | Research| Snort Rules | 2.6.0   | test description4 |

    And a user with id "1" has a parent with id "2"

    Then I wait for "3" seconds
    And  I goto "/users"
    Then I click "h_clinton"
    And  I should not see "glyphicon-pencil"

  @javascript
  Scenario: A user can download their bugs from bugzilla,
            but not go to another users page and download their bugs.
    Given a user with role "analyst" exists and is logged in
    And the following users exist
      | id | email                | cvs_username | display_name        | parent_id |
      | 2  | rainbows@email.com   | rainbow_b    | Rainbow Brite       |           |
      | 3  | hclinton@email.com   | h_clinton    | Hillary Clinton     |     2     |
      | 4  | dtrump@email.com     | d_drumph     | Donald Trump        |           |

    And the following bugs exist:
      | id      | bugzilla_id | state  | user_id | summary             | product | component   | version | description       |
      |222222   | 222222      | OPEN   | 3       | [BP][NSS] fixed bug | Research| Snort Rules | 2.6.0   | test description3 |
      |333333   | 333333      | OPEN   | 1       | [TELUS] broken bug  | Research| Snort Rules | 2.6.0   | test description4 |

    And a user with id "1" has a parent with id "2"

    Then I wait for "3" seconds
    And  I goto "/users/1"
    Then I should see link with class "glyphicon-cloud-download"
    And  I goto "/users/3"
    Then I should not see link with class "glyphicon-cloud-download"

  @javascript
  Scenario: A non-manager admin user can edit the role for any user.
    Given a user with role "admin" exists and is logged in
    And the following users exist
      | id | email                | cvs_username | display_name        | parent_id |
      | 2  | rainbows@email.com   | rainbow_b    | Rainbow Brite       |           |
      | 3  | hclinton@email.com   | h_clinton    | Hillary Clinton     |     2     |
      | 4  | dtrump@email.com     | d_drumph     | Donald Trump        |           |

    And the following roles exist:
      | role           |
      | analyst        |
      | committer      |

    And the following bugs exist:
      | id      | bugzilla_id | state  | user_id | summary             | product | component   | version | description       |
      |222222   | 222222      | OPEN   | 3       | [BP][NSS] fixed bug | Research| Snort Rules | 2.6.0   | test description3 |
      |333333   | 333333      | OPEN   | 1       | [TELUS] broken bug  | Research| Snort Rules | 2.6.0   | test description4 |

    And a user with id "1" has a parent with id "2"

    Then I wait for "3" seconds
    And  I goto "/users"
    Then I click "h_clinton"
    Then I click the link with data-target "#roleModal_3"
    And I wait for "1" seconds
    And I should see "Update Role(s) for h_clinton"
    And I check "analyst"
    Then I click "Save changes"
    And I should see "h_clinton updated successfully"
    And I should see "analyst"
    And I should not see "committer"


  @javascript
  Scenario: A manager user can go to the users index page and see only their co-workers and team members.
            A manager can access the relationships page.
    Given a manager exists and is logged in
    And the following users exist
      | id | email                | cvs_username | display_name        | parent_id |
      | 3  | hclinton@email.com   | h_clinton    | Hillary Clinton     | 1         |
      | 4  | dtrump@email.com     | d_drumph     | Donald Trump        | 1         |
      | 5  | master@email.com     | master       | Master User         |           |
      | 2  | rainbows@email.com   | rainbow_b    | Rainbow Brite       |  5        |

    And a user with id "1" has a parent with id "5"

    And the following bugs exist:
      | id      | bugzilla_id | state  | user_id | summary             | product | component   | version | description       |
      |222222   | 222222      | OPEN   | 3       | [BP][NSS] fixed bug | Research| Snort Rules | 2.6.0   | test description3 |
      |333333   | 333333      | OPEN   | 1       | [TELUS] broken bug  | Research| Snort Rules | 2.6.0   | test description4 |

    Then I wait for "3" seconds
    And  I goto "/users"
    And  I should see "h_clinton"
    And  I should see "d_drumph"
    And  I should see "rainbow_b"
    Then I goto "/users/1/relationships"
    And  I should see "d_drumph"

  @javascript
  Scenario: A manager can add and remove team members on the relationships page.
    Given a manager exists and is logged in
    And the following users exist
      | id | email                | cvs_username  | display_name        | parent_id |
      | 2  | rainbows@email.com   | rainbow_b     | Rainbow Brite       |  1        |
      | 3  | hclinton@email.com   | h_clinton     | Hillary Clinton     |  2        |
      | 4  | dtrump@email.com     | d_drumph      | Donald Trump        |           |
      | 5  | gjohns@email.com     | g_johnson     | Gary Johnson        |           |
      | 6  | tbeary@email.com     | t_bear        | Teddy Bear          |  5        |


    Then I wait for "3" seconds
    And  I goto "/users/1/relationships"
    And  I should see "h_clinton"
    And  "-- Hillary Clinton (h_clinton)" should not be in the "child_id" dropdown list
    And  I select "Donald Trump (d_drumph)" from "child_id"
    Then I click "Add"
    Then I should see "d_drumph successfully added"
    And  I select "- Teddy Bear (t_bear)" from "child_id"
    Then I should see "- Teddy Bear (t_bear) is on a team already. Are you sure you want to move - Teddy Bear (t_bear) to another team?"
    Then I click "Ok"
    Then I click "Add"
    And  I should see "t_bear successfully added"

  @javascript
  Scenario: A manager can edit roles of team members on relationships page.
    Given a manager exists and is logged in
    And the following users exist
      | id | email                | cvs_username  | display_name        | parent_id |
      | 2  | rainbows@email.com   | rainbow_b     | Rainbow Brite       | 1         |
      | 3  | hclinton@email.com   | h_clinton     | Hillary Clinton     | 2         |
      | 4  | dtrump@email.com     | d_drumph      | Donald Trump        | 1         |
      | 5  | gjohns@email.com     | g_johnson     | Gary Johnson        |           |
      | 6  | tbeary@email.com     | t_bear        | Teddy Bear          | 2         |

    And the following roles exist:
      | role           |
      | analyst        |
      | committer      |

    Then I wait for "3" seconds
    And  I goto "/users/1/relationships"
    And  I should see "h_clinton"
    And  "Hillary Clinton (h_clinton)" should not be in the "child_id" dropdown list
    Then I click the link with data-target "#roleModal_3"
    Then I wait for "1" seconds
    Then I should see "Update Role(s) for h_clinton"
    Then I check "analyst"
    Then I click "Save changes"
    Then I should see "h_clinton updated successfully."
    And I should see "analyst"
    And I should not see "committer"
    And I click the link with data-target "#roleModal_4"
    Then I wait for "1" seconds
    Then I should see "Update Role(s) for d_drumph"
    Then I check "analyst"
    Then I check "committer"
    Then I click "Save changes"
    Then I should see "d_drumph updated successfully."
    Then I should see "analyst, committer"

  @javascript
  Scenario: A manager can edit members subordinate manager teams on relationships page.
    Given a manager exists and is logged in
    And the following users exist
      | id | email                | cvs_username  | display_name        | parent_id |
      | 2  | rainbows@email.com   | rainbow_b     | Rainbow Brite       | 1         |
      | 3  | hclinton@email.com   | h_clinton     | Hillary Clinton     | 2         |
      | 4  | dtrump@email.com     | d_drumph      | Donald Trump        | 1         |
      | 5  | gjohns@email.com     | g_johnson     | Gary Johnson        |           |
      | 6  | tbeary@email.com     | t_bear        | Teddy Bear          | 2         |

    And the following roles exist:
      | role           |
      | analyst        |
      | committer      |

    And a user with id "2" has a role of "manager"

    Then I wait for "3" seconds
    And  I goto "/users/1/relationships"
    Then I click the link with data-target "#teamModal_2"
    Then I wait for "1" seconds
    Then I should see "Add to rainbow_b's team"
    Then select "Gary Johnson (g_johnson)" from "child_id" within ".modal-body"
    Then click button "Add" within ".modal-body"
    Then I should see "g_johnson successfully added"


  @javascript
  Scenario: A manager user can go to a users show page and update their metrics timeframe preference.
    Given a manager exists and is logged in
    And the following users exist
      | id | email                | cvs_username | display_name        | parent_id |
      | 2  | rainbows@email.com   | rainbow_b    | Rainbow Brite       | 1         |
      | 3  | hclinton@email.com   | h_clinton    | Hillary Clinton     | 1         |
      | 4  | dtrump@email.com     | d_drumph     | Donald Trump        | 1         |

    Then I wait for "3" seconds
    And  I goto "/users"
    And  I goto "/users/3"
    And  I should see "Bug status changes last 7 days"
    Then I click "change"
    And  I select "30" from "user_metrics_timeframe"
    Then I click "done"
    And  I wait for "2" seconds
    Then I should see "Bug status changes last 30 days"



  @javascript
  Scenario: Bugs should be separated into the proper open, closed and pending tabs
    Given a manager exists and is logged in
    And the following users exist
      | id | email                | cvs_username | display_name        | parent_id |
      | 3  | hclinton@email.com   | h_clinton    | Hillary Clinton     | 1         |


    And the following bugs exist:
      | id      | bugzilla_id | state     | user_id | summary             | product | component   | version | description       |
      |222222   | 222222      | OPEN      | 3       | [BP][NSS] fixed bug | Research| Snort Rules | 2.6.0   | test description3 |
      |333333   | 333333      | PENDING   | 3       | [TELUS] broken bug  | Research| Snort Rules | 2.6.0   | test description4 |

    Then I wait for "3" seconds
    And  I goto "/users/3"
    And  I should see "[BP][NSS] fixed bug"
    And  I should not see "[TELUS] broken bug"
    Then I click "pending (1)"
    And  I should see "[TELUS] broken bug"
    And  I should not see "[BP][NSS] fixed bug"


  ### Scenarios User search

  @javascript
  Scenario: A user can search using email
    Given a user with role "analyst" exists and is logged in
    And I wait for "3" seconds
    And the following users exist
      | email              |
      | carlzipp@cisco.com |
      | davecarr@cisco.com |
      | porsche@cisco.com  |
      | bentley@cisco.com  |
    When I goto "/users"
    Then I should see a user search form
    Given I fill in "user_search_name" with "CAR"
    When I click button "search"
    Then I see a user_searches result for name "carlzipp@cisco.com"
    And I see a user_searches result for name "davecarr@cisco.com"
    And I do not see a user_searches result for name "porsche@cisco.com"
    And I do not see a user_searches result for name "bentley@cisco.com"

  @javascript
  Scenario: A user can search using a users display name
    Given a user with role "analyst" exists and is logged in
    And I wait for "3" seconds
    And the following users exist
      | email            | display_name        |
      | email1@cisco.com | Carl Zipp           |
      | email2@cisco.com | David Carr          |
      | email3@cisco.com | Porsche Bugatti     |
      | email4@cisco.com | Bentley Ford        |
    Given I goto "/users"
    Given I fill in "user_search_name" with "CAR"
    When I click button "search"
    Then I see a user_searches result for name "Carl Zipp"
    And I see a user_searches result for name "David Carr"
    And I do not see a user_searches result for name "Porsche Bugatti"
    And I do not see a user_searches result for name "Bentley Ford"

  @javascript
  Scenario: A user can search using CVS user name
    Given a user with role "analyst" exists and is logged in
    And I wait for "3" seconds
    And the following users exist
      | email            | cvs_username |
      | email1@cisco.com | carlzipp     |
      | email2@cisco.com | davecarr     |
      | email3@cisco.com | porsche      |
      | email4@cisco.com | bentley      |
    Given I goto "/users"
    Given I fill in "user_search_name" with "CAR"
    When I click button "search"
    Then I see a user_searches result for name "carlzipp"
    And I see a user_searches result for name "davecarr"
    And I do not see a user_searches result for name "porsche"
    And I do not see a user_searches result for name "bentley"

  @javascript
  Scenario: A user can search using CEC username
    Given a user with role "analyst" exists and is logged in
    And I wait for "3" seconds
    And the following users exist
      | email            | cec_username |
      | email1@cisco.com | carlzipp     |
      | email2@cisco.com | davecarr     |
      | email3@cisco.com | porsche      |
      | email4@cisco.com | bentley      |
    Given I goto "/users"
    Given I fill in "user_search_name" with "CAR"
    When I click button "search"
    Then I see a user_searches result for name "carlzipp"
    And I see a user_searches result for name "davecarr"
    And I do not see a user_searches result for name "porsche"
    And I do not see a user_searches result for name "bentley"

  @javascript
  Scenario: A user can search using Kerberos Login
    Given a user with role "analyst" exists and is logged in
    And I wait for "3" seconds
    And the following users exist
      | email            | kerberos_login |
      | email1@cisco.com | carlzipp       |
      | email2@cisco.com | davecarr       |
      | email3@cisco.com | porsche        |
      | email4@cisco.com | bentley        |
    Given I goto "/users"
    Given I fill in "user_search_name" with "CAR"
    When I click button "search"
    Then I see a user_searches result for name "carlzipp"
    And I see a user_searches result for name "davecarr"
    And I do not see a user_searches result for name "porsche"
    And I do not see a user_searches result for name "bentley"


  ### Scenarios User Role access ###

  @javascript
  Scenario: An analyst should be able to do everything
            related to a bug except for commit a rule
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | id      | bugzilla_id | state  | user_id | summary             | product | component   | version | description       |
      |333333   | 333333      | OPEN   | 1       | [TELUS] broken bug  | Research| Snort Rules | 2.6.0   | test description4 |
    Given I wait for "3" seconds
    And I goto "/bugs/333333"
    When I click ".rules-tab"
    Then I should see content "edit" within ".top-bar"
    And I should see content "create" within ".top-bar"
    And I should see content "remove" within ".top-bar"
    And I should not see content "commit" within ".top-bar"
    When I click ".attachments-tab"
    Then I should see button with class "create_attachment"
    When I click ".notes-tab"
    Then I should see content "edit" within "#notes_form"
    And I should see content "publish" within "#notes_form"

  @javascript
  Scenario: A committer should be able to do everything related to a bug
    Given a user with role "committer" exists and is logged in
    And the following bugs exist:
      | id      | bugzilla_id | state  | user_id | summary             | product | component   | version | description       |
      |333333   | 333333      | OPEN   | 1       | [TELUS] broken bug  | Research| Snort Rules | 2.6.0   | test description4 |
    Given I wait for "3" seconds
    And I goto "/bugs/333333"
    When I click ".rules-tab"
    Then I should see content "edit" within ".top-bar"
    And I should see content "create" within ".top-bar"
    And I should see content "remove" within ".top-bar"
    And I should see content "commit" within ".top-bar"
    When I click ".attachments-tab"
    Then I should see button with class "create_attachment"
    When I click ".notes-tab"
    Then I should see content "edit" within "#notes_form"
    And I should see content "publish" within "#notes_form"

  @javascript
  Scenario: A manager should be able to do everything related to a bug except commit
    Given a user with role "manager" exists and is logged in
    And the following bugs exist:
      | id      | bugzilla_id | state  | user_id | summary             | product | component   | version | description       |
      |333333   | 333333      | OPEN   | 1       | [TELUS] broken bug  | Research| Snort Rules | 2.6.0   | test description4 |
    Given I wait for "3" seconds
    And I goto "/bugs/333333"
    When I click ".rules-tab"
    Then I should see content "edit" within ".top-bar"
    And I should see content "create" within ".top-bar"
    And I should see content "remove" within ".top-bar"
    And I should not see content "commit" within ".top-bar"
    When I click ".attachments-tab"
    Then I should see button with class "create_attachment"
    When I click ".notes-tab"
    Then I should see content "edit" within "#notes_form"
    And I should see content "publish" within "#notes_form"

  @javascript @allow-rescue
  Scenario: A build coordinator should be able to view everything related to a bug but not alter it
            A build coordinator cannot create new bugs
    Given a user with role "build coordinator" exists and is logged in
    And the following bugs exist:
      | id      | bugzilla_id | state  | user_id | summary             | product | component   | version | description       |
      |333333   | 333333      | OPEN   | 1       | [TELUS] broken bug  | Research| Snort Rules | 2.6.0   | test description4 |
    Given I wait for "3" seconds
    And  I goto "/bugs/new"
    Then I should see "You are not authorized to new bug."
    And I goto "/bugs/333333"
    When I click ".rules-tab"
    Then I should not see content "edit" within ".top-bar"
    And I should not see content "create" within ".top-bar"
    And I should not see content "remove" within ".top-bar"
    And I should not see content "commit" within ".top-bar"
    When I click ".attachments-tab"
    Then I should not see button with class "create_attachment"
    When I click ".notes-tab"
    Then I should not see content "edit" within "#notes_form"
    And I should not see content "publish" within "#notes_form"

  @javascript
  Scenario: An analyst should see a list of their bugs first time in bugs index
    Given a user with role "analyst" exists and is logged in
    And the following bugs exist:
      | bugzilla_id | state | user_id | summary                                     | product  | component   | version | description       |
      | 111111      | OPEN  | 1       | [[TELUS][VULN][BP] [SID] 22078 test summary | Research | Snort Rules | 2.6.0   | test description  |
      | 222222      | OPEN  | 2       | No Tags in this one                         | Research | Snort Rules | 2.6.0   | test description2 |
      | 222222      | FIXED | 2       | [BP][NSS] fixed bug                         | Research | Snort Rules | 2.6.0   | test description3 |
    Then I wait for "3" seconds
    And  I goto "/bugs"
    And  I should see "[[TELUS][VULN][BP] [SID] 22078 test summary"
    And  I should not see "[BP][NSS] fixed bug"

  @javascript
  Scenario: A committer should see a list of pending bugs first time in bugs index
    Given a user with role "committer" exists and is logged in
    And the following bugs exist:
      | bugzilla_id | state   | user_id | summary                                                 | product  | component   | version | description       |
      | 111111      | OPEN    | 1       | [[TELUS][VULN][BP] [SID] 22078 test summary             | Research | Snort Rules | 2.6.0   | test description  |
      | 222222      | OPEN    | 2       | No Tags in this one                                     | Research | Snort Rules | 2.6.0   | test description2 |
      | 222222      | FIXED   | 2       | [BP][NSS] fixed bug                                     | Research | Snort Rules | 2.6.0   | test description3 |
      | 333333      | PENDING | 2       | Pending bug I should see                                | Research | Snort Rules | 2.6.0   | test description3 |
    Then I wait for "3" seconds
    And  I goto "/bugs"
    And  I should see "Pending bug I should see"
    And  I should not see "[BP][NSS] fixed bug"

  @javascript
  Scenario: A build coordinator should see a list of fixed bugs first time in bugs index
    Given a user with role "build coordinator" exists and is logged in
    And the following bugs exist:
      | bugzilla_id | state   | user_id | summary                                                 | product  | component   | version | description       |
      | 111111      | OPEN    | 1       | [[TELUS][VULN][BP] [SID] 22078 test summary             | Research | Snort Rules | 2.6.0   | test description  |
      | 222222      | OPEN    | 2       | No Tags in this one                                     | Research | Snort Rules | 2.6.0   | test description2 |
      | 222222      | FIXED   | 2       | [BP][NSS] fixed bug                                     | Research | Snort Rules | 2.6.0   | test description3 |
      | 333333      | PENDING | 2       | Pending bug I should see                                | Research | Snort Rules | 2.6.0   | test description3 |
    Then I wait for "3" seconds
    And  I goto "/bugs"
    And  I should see "[BP][NSS] fixed bug"
    And  I should not see "Pending bug I should see"
    And  I should not see "[[TELUS][VULN][BP] [SID] 22078 test summary"

