Feature: User Accounts
  In order to provide account services
  As a user
  I want to provide user authentication

  ### Scenarios login ###

  @javascript
  Scenario: A user with proper credentials should get logged in
            and redirected to the bugs page
    Given current user exists
    And I visit the root url
    And I should see "Please sign in using your Cisco credentials"
    When the user signs in
    Then I should not see "Please sign in using your Cisco credentials"
    And I should see "/escalations/users" in the current url

  @javascript
  Scenario: A user logging in not in the database should be added to the database
    Given current user not in database
    When the user signs in
    And  current user should be in database

  @javascript
  Scenario: A user logging in, in the database for a bug, should have the kerberos login updated
    Given current user is a bug user
    Then current user should be in database
    And  current user should not have kerberos login
    When the user signs in
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
  Scenario: A user can see accurate ticket category counts on the users index page
    Given a manager exists and is logged in
    And the following users exist
      | id | email                | cvs_username | display_name        | parent_id |
      | 3  | hclinton@email.com   | h_clinton    | Hillary Clinton     | 1         |
    Then I wait for "3" seconds
    And  I goto "/users"
    And  I should not see "5"
    And  I should not see "3"
    And  I should not see "4"
    And the following bugs exist:
      | id      | bugzilla_id | state     | user_id | summary              | product | component   | version | description       |
      |2        | 2           | OPEN      | 3       | [BP][NSS] fixed bug  | Research| Snort Rules | 2.6.0   | test description3 |
      |21       | 21          | OPEN      | 3       | [BP][NSS] fixed bug  | Research| Snort Rules | 2.6.0   | test description3 |
      |22       | 22          | OPEN      | 3       | [BP][NSS] fixed bug  | Research| Snort Rules | 2.6.0   | test description3 |
      |23       | 23          | OPEN      | 3       | [BP][NSS] fixed bug  | Research| Snort Rules | 2.6.0   | test description3 |
      |24       | 24          | OPEN      | 3       | [BP][NSS] fixed bug  | Research| Snort Rules | 2.6.0   | test description3 |
      |3        | 3           | PENDING   | 3       | [TELUS] broken bug   | Research| Snort Rules | 2.6.0   | test description4 |
      |31       | 31          | PENDING   | 3       | [TELUS] broken bug   | Research| Snort Rules | 2.6.0   | test description4 |
      |32       | 32          | PENDING   | 3       | [TELUS] broken bug   | Research| Snort Rules | 2.6.0   | test description4 |
      |4        | 4           | FIXED     | 3       | [TELUS] broken bug2  | Research| Snort Rules | 2.6.0   | test description  |
      |41       | 41          | DUPLICATE | 3       | [TELUS] broken bug3  | Research| Snort Rules | 2.6.0   | test description  |
      |42       | 42          | WONTFIX   | 3       | [TELUS] broken bug4  | Research| Snort Rules | 2.6.0   | test description  |
      |43       | 43          | INVALID   | 3       | [TELUS] broken bug5  | Research| Snort Rules | 2.6.0   | test description  |


    Then I wait for "3" seconds
    And  I goto "/users"
    And  I should see "5"
    And  I should see "3"
    And  I should see "4"


  @javascript
  Scenario: A non-manager user can go to the users index page and see only their co-workers.
            Assigned bugs should be on users show page.
            A non-manager cannot get to the relationships section.
    Given a user with role "analyst" exists and is logged in
    And the following users exist
      | id | email                      | cvs_username | display_name        | parent_id | cec_username |
      | 2  | rainbows@email.com         | rainbow_b    | Rainbow Brite       |           | rainbow_b    |
      | 3  | hclinton@email.com         | h_clinton    | Hillary Clinton     |  2        | h_clinton    |
      | 4  | dtrump@email.com           | d_drumph     | Donald Trump        |           | d_drumph     |

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
    Then I click the span with data-target "#roleModal_3"
    And I wait for "1" seconds
    And I should see "Update Role(s) for h_clinton"
    And I check "analyst"
    Then I click "Save changes"
    And I should see "h_clinton updated successfully"
    And I should see "analyst"


  @javascript
  Scenario: An admin user can make any user an admin, including managers.
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

    And a user with id "1" has a parent with id "3"

    Then I wait for "3" seconds
    And  I goto "/users/1"
    Then I click "h_clinton"
    Then I click the span with data-target "#roleModal_3"
    And I wait for "1" seconds
    And I should see "Update Role(s) for h_clinton"
    And I check "admin"
    Then I click "Save changes"
    And I should see "h_clinton updated successfully"
    And I should see "admin"

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
      | id | email                | cvs_username  | display_name        | parent_id | cec_username |
      | 2  | rainbows@email.com   | rainbow_b     | Rainbow Brite       |  1        | rainbow_b    |
      | 3  | hclinton@email.com   | h_clinton     | Hillary Clinton     |  2        | h_clinton    |
      | 4  | dtrump@email.com     | d_drumph      | Donald Trump        |           | d_drumph     |
      | 5  | gjohns@email.com     | g_johnson     | Gary Johnson        |           | g_johnson    |
      | 6  | tbeary@email.com     | t_bear        | Teddy Bear          |  5        | t_bear       |


    Then I wait for "3" seconds
    And  I goto "/users/1/relationships"
    And I click ".glyphicon-chevron-right"
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
      | id | email                | cvs_username  | display_name        | parent_id | cec_username |
      | 2  | rainbows@email.com   | rainbow_b     | Rainbow Brite       | 1         | rainbow_b    |
      | 3  | hclinton@email.com   | h_clinton     | Hillary Clinton     | 2         | h_clinton    |
      | 4  | dtrump@email.com     | d_drumph      | Donald Trump        | 1         | d_drumph     |
      | 5  | gjohns@email.com     | g_johnson     | Gary Johnson        |           | g_johnson    |
      | 6  | tbeary@email.com     | t_bear        | Teddy Bear          | 2         | t_bear       |

    And the following roles exist:
      | role           |
      | analyst        |
      | committer      |

    Then I wait for "3" seconds
    And  I goto "/users/1/relationships"
    And I click ".glyphicon-chevron-right"
    And  I should see "h_clinton"
    And  "Hillary Clinton (h_clinton)" should not be in the "child_id" dropdown list
    Then I click the link with data-target "#roleModal_3"
    Then I wait for "1" seconds
    Then I should see "Update Role(s) for h_clinton"
    Then I check "analyst"
    Then I click "Save changes"
    Then I should see "h_clinton updated successfully."
    Then I click ".glyphicon-chevron-right"
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
      | id | email                | cvs_username  | display_name        | parent_id | cec_username |
      | 2  | rainbows@email.com   | rainbow_b     | Rainbow Brite       | 1         | rainbow_b    |
      | 3  | hclinton@email.com   | h_clinton     | Hillary Clinton     | 2         | h_clinton    |
      | 4  | dtrump@email.com     | d_drumph      | Donald Trump        | 1         | d_drumph     |
      | 5  | gjohns@email.com     | g_johnson     | Gary Johnson        |           | g_johnson    |
      | 6  | tbeary@email.com     | t_bear        | Teddy Bear          | 2         | t_bear       |

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
  Scenario: A user can go to a metrics page and update their metrics timeframe preference.
    Given a user with role "analyst" exists and is logged in
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

  @javascript
  Scenario: Bugs in open tab should be paginated
    Given a manager exists and is logged in
    And the following users exist
      | id | email                | cvs_username | display_name        | parent_id |
      | 3  | hclinton@email.com   | h_clinton    | Hillary Clinton     | 1         |


    And the following bugs exist:
      | id      | bugzilla_id | state    | user_id | summary              | product | component   | version | description       |
      |222222   | 222222      | OPEN     | 3       | [BP][NSS] fixed bug  | Research| Snort Rules | 2.6.0   | test description3 |
      |333333   | 333333      | OPEN     | 3       | [TELUS] broken bug   | Research| Snort Rules | 2.6.0   | test description4 |
      |4        | 4           | OPEN     | 3       | [TELUS] broken bug2  | Research| Snort Rules | 2.6.0   | test description  |
      |5        | 5           | OPEN     | 3       | [TELUS] broken bug3  | Research| Snort Rules | 2.6.0   | test description  |
      |6        | 6           | OPEN     | 3       | [TELUS] broken bug4  | Research| Snort Rules | 2.6.0   | test description  |
      |7        | 7           | OPEN     | 3       | [TELUS] broken bug5  | Research| Snort Rules | 2.6.0   | test description  |
      |8        | 8           | OPEN     | 3       | [TELUS] broken bug6  | Research| Snort Rules | 2.6.0   | test description  |
      |9        | 9           | OPEN     | 3       | [TELUS] broken bug7  | Research| Snort Rules | 2.6.0   | test description  |
      |10       | 10          | OPEN     | 3       | [TELUS] broken bug8  | Research| Snort Rules | 2.6.0   | test description  |
      |11       | 11          | OPEN     | 3       | [TELUS] broken bug9  | Research| Snort Rules | 2.6.0   | test description  |
      |12       | 12          | OPEN     | 3       | [TELUS] broken bug10 | Research| Snort Rules | 2.6.0   | test description  |
      |13       | 13          | OPEN     | 3       | [TELUS] broken bug11 | Research| Snort Rules | 2.6.0   | test description  |
      |14       | 14          | OPEN     | 3       | [TELUS] broken bug12 | Research| Snort Rules | 2.6.0   | test description  |
      |15       | 15          | OPEN     | 3       | [TELUS] broken bug13 | Research| Snort Rules | 2.6.0   | test description  |
      |16       | 16          | OPEN     | 3       | [TELUS] broken bug14 | Research| Snort Rules | 2.6.0   | test description  |
      |17       | 17          | OPEN     | 3       | [TELUS] broken bug15 | Research| Snort Rules | 2.6.0   | test description  |
      |18       | 18          | OPEN     | 3       | [TELUS] broken bug16 | Research| Snort Rules | 2.6.0   | test description  |
      |19       | 19          | OPEN     | 3       | [TELUS] broken bug17 | Research| Snort Rules | 2.6.0   | test description  |
      |20       | 20          | OPEN     | 3       | [TELUS] broken bug18 | Research| Snort Rules | 2.6.0   | test description  |


    Then I wait for "3" seconds
    And  I goto "/users/3"
    And  I should see "[TELUS] broken bug2"
    And  I should not see "[TELUS] broken bug12"
    Then I click "Next"
    And  I should see "[TELUS] broken bug12"

  @javascript
  Scenario: Bugs in pending tab should be paginated
    Given a manager exists and is logged in
    And the following users exist
      | id | email                | cvs_username | display_name        | parent_id |
      | 3  | hclinton@email.com   | h_clinton    | Hillary Clinton     | 1         |


    And the following bugs exist:
      | id      | bugzilla_id | state     | user_id | summary              | product | component   | version | description       |
      |222222   | 222222      | OPEN      | 3       | [BP][NSS] fixed bug  | Research| Snort Rules | 2.6.0   | test description3 |
      |333333   | 333333      | PENDING   | 3       | [TELUS] broken bug   | Research| Snort Rules | 2.6.0   | test description4 |
      |4        | 4           | PENDING   | 3       | [TELUS] broken bug2  | Research| Snort Rules | 2.6.0   | test description  |
      |5        | 5           | PENDING   | 3       | [TELUS] broken bug3  | Research| Snort Rules | 2.6.0   | test description  |
      |6        | 6           | PENDING   | 3       | [TELUS] broken bug4  | Research| Snort Rules | 2.6.0   | test description  |
      |7        | 7           | PENDING   | 3       | [TELUS] broken bug5  | Research| Snort Rules | 2.6.0   | test description  |
      |8        | 8           | PENDING   | 3       | [TELUS] broken bug6  | Research| Snort Rules | 2.6.0   | test description  |
      |9        | 9           | PENDING   | 3       | [TELUS] broken bug7  | Research| Snort Rules | 2.6.0   | test description  |
      |10       | 10          | PENDING   | 3       | [TELUS] broken bug8  | Research| Snort Rules | 2.6.0   | test description  |
      |11       | 11          | PENDING   | 3       | [TELUS] broken bug9  | Research| Snort Rules | 2.6.0   | test description  |
      |12       | 12          | PENDING   | 3       | [TELUS] broken bug10 | Research| Snort Rules | 2.6.0   | test description  |
      |13       | 13          | PENDING   | 3       | [TELUS] broken bug11 | Research| Snort Rules | 2.6.0   | test description  |
      |14       | 14          | PENDING   | 3       | [TELUS] broken bug12 | Research| Snort Rules | 2.6.0   | test description  |
      |15       | 15          | PENDING   | 3       | [TELUS] broken bug13 | Research| Snort Rules | 2.6.0   | test description  |
      |16       | 16          | PENDING   | 3       | [TELUS] broken bug14 | Research| Snort Rules | 2.6.0   | test description  |
      |17       | 17          | PENDING   | 3       | [TELUS] broken bug15 | Research| Snort Rules | 2.6.0   | test description  |
      |18       | 18          | PENDING   | 3       | [TELUS] broken bug16 | Research| Snort Rules | 2.6.0   | test description  |
      |19       | 19          | PENDING   | 3       | [TELUS] broken bug17 | Research| Snort Rules | 2.6.0   | test description  |
      |20       | 20          | PENDING   | 3       | [TELUS] broken bug18 | Research| Snort Rules | 2.6.0   | test description  |


    Then I wait for "3" seconds
    And  I goto "/users/3"
    And  I should see "[BP][NSS] fixed bug"
    And  I should not see "[TELUS] broken bug"

    Then I click "pending (18)"
    And  I should see "[TELUS] broken bug"
    And  I should not see "[BP][NSS] fixed bug"

    Then I click "Next"
    And  I should see "[TELUS] broken bug12"

  ### Scenarios User search

  @javascript
  Scenario: A user can search using email
    Given a user with role "manager" exists and is logged in
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
    Given a user with role "manager" exists and is logged in
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
    Given a user with role "manager" exists and is logged in
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
    Then I see a user_searches result for name "email1@cisco.com"
    And I see a user_searches result for name "email2@cisco.com"
    And I do not see a user_searches result for name "email3@cisco.com"
    And I do not see a user_searches result for name "email4@cisco.com"

  @javascript
  Scenario: A user can search using CEC username
    Given a user with role "manager" exists and is logged in
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
    Then I see a user_searches result for name "email1@cisco.com"
    And I see a user_searches result for name "email2@cisco.com"
    And I do not see a user_searches result for name "email3@cisco.com"
    And I do not see a user_searches result for name "email4@cisco.com"

  @javascript
  Scenario: A user can search using Kerberos Login
    Given a user with role "manager" exists and is logged in
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
    Then I see a user_searches result for name "email1@cisco.com"
    And I see a user_searches result for name "email2@cisco.com"
    And I do not see a user_searches result for name "email3@cisco.com"
    And I do not see a user_searches result for name "email4@cisco.com"


  ### Scenarios User Role access ###

  @javascript
  Scenario: An Admin user should be able to get to the admin section
    Given a user with role "admin" exists and is logged in
    And I wait for "3" seconds
    And I go to "/admin"
    Then I should see "Admin Page"


  @javascript
  Scenario: An non Admin user should not be able to get to the admin section
    Given a user with role "analyst" exists and is logged in
    And I wait for "3" seconds
    And I go to "/admin"
    Then I should not see "Admin Page"
    And I should see "You are not authorized"

