Feature: User Accounts
  In order to provide account services
  As a user
  I want to provide user authentication

  ### Scenarios login ###

# The sign in page does not handle creating a user from the kerberos authentication.
# The sign in page is not longer used in tests, so "When the user signs in" does not go to the sign in page.
#  @javascript
#  Scenario: A user with proper credentials should get logged in and redirected to the bugs page
#    Given current user exists
#    When I visit the root url
#    Then I should see "/escalations/sessions/new" in the current url
#    And I should see "Please sign in using your Cisco credentials"
#    When the user signs in
#    Then I should not see "Please sign in using your Cisco credentials"
#    And I should see "/escalations/users" in the current url
#
#  @javascript
#  Scenario: A user logging in not in the database should be added to the database
#    Given current user not in database
#    When the user signs in
#    And  current user should be in database
#
#  @javascript
#  Scenario: A user logging in, in the database for a bug, should have the kerberos login updated
#    Given current user is a bug user
#    And  current user should be in database
#    Then current user should not have kerberos login
#    When the user signs in
#    Then current user should be in database
#    And  current user should have kerberos login


  ### Scenarios User management ###

  @javascript
  Scenario: A non-manager non-admin user cannot edit the role for any user.
    Given a user with role "analyst" exists and is logged in
    And the following users exist
      | id | email                | cvs_username | display_name        | parent_id |
      | 2  | rainbows@email.com   | rainbow_b    | Rainbow Brite       |           |
      | 3  | hclinton@email.com   | h_clinton    | Hillary Clinton     |     2     |
      | 4  | dtrump@email.com     | d_drumph     | Donald Trump        |           |

    And a user with id "1" has a parent with id "2"

    Then I wait for "3" seconds
    And  I goto "/users"
    Then I click "h_clinton"
    And  I should not see "edit-button"


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

    And a user with id "1" has a parent with id "2"

    Then I wait for "3" seconds
    And  I goto "/users/3"
    Then I click the button with data-target "#roleModal_3"
    And I wait for "1" seconds
    And I should see "Edit User H_clinton"
    And I check "analyst"
    Then I click "Save"
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

    And a user with id "1" has a parent with id "3"

    Then I wait for "3" seconds
    And  I goto "/users/3"
    Then I click the button with data-target "#roleModal_3"
    And I wait for "1" seconds
    And I should see "Edit User H_clinton"
    And I check "admin"
    Then I click "Save"
    And I should see "h_clinton updated successfully"
    And I should see "admin"


  @javascript
  Scenario: A manager user can go to the users index page and see only their co-workers and team members.
    Given a manager exists and is logged in
    And the following users exist
      | id | email                | cvs_username | display_name        | parent_id |
      | 3  | hclinton@email.com   | h_clinton    | Hillary Clinton     | 1         |
      | 4  | dtrump@email.com     | d_drumph     | Donald Trump        | 1         |
      | 5  | master@email.com     | master       | Master User         |           |
      | 2  | rainbows@email.com   | rainbow_b    | Rainbow Brite       |  5        |

    And a user with id "1" has a parent with id "5"

    Then I wait for "3" seconds
    And  I goto "/users"
    And  I should see "h_clinton"
    And  I should see "d_drumph"
    And  I should see "rainbow_b"


  @javascript
  Scenario: A manager can add and remove their team members on the users index page.
    Given a user with id "2" has a role "manager" and is logged in
    And the following users exist
      | id | email                | cvs_username  | display_name        | parent_id | cec_username |
      | 3  | hclinton@email.com   | h_clinton     | Hillary Clinton     |  2        | h_clinton    |
      | 4  | dtrump@email.com     | d_drumph      | Donald Trump        |           | d_drumph     |
      | 5  | gjohns@email.com     | g_johnson     | Gary Johnson        |           | g_johnson    |
      | 6  | tbeary@email.com     | t_bear        | Teddy Bear          |  5        | t_bear       |

    And  I goto "/users"
    And  I should see "h_clinton"
    And  I click "#add_user_button_2"
    And  "Hillary Clinton (h_clinton)" should not be in the "users_for_2" dropdown list
    And  I select "Donald Trump (d_drumph)" from "users_for_2"
    Then I click "Add User"
    Then I should see "d_drumph successfully added"


  @javascript
  Scenario: A manager can edit roles of their team members on users index page.
    Given a user with id "2" has a role "manager" and is logged in
    And the following users exist
      | id | email                | cvs_username  | display_name        | parent_id | cec_username |
      | 3  | hclinton@email.com   | h_clinton     | Hillary Clinton     | 2         | h_clinton    |
      | 4  | dtrump@email.com     | d_drumph      | Donald Trump        | 2         | d_drumph     |
      | 5  | gjohns@email.com     | g_johnson     | Gary Johnson        |           | g_johnson    |
      | 6  | tbeary@email.com     | t_bear        | Teddy Bear          | 2         | t_bear       |

    And the following roles exist:
      | role           |
      | analyst        |
      | committer      |

    Then I wait for "3" seconds
    And  I goto "/users"
    And  I should see "h_clinton"
    Then I click the button with data-target "#roleModal_3"
    Then I wait for "1" seconds
    Then I should see "Edit User H_clinton"
    Then I check "analyst"
    Then I click "Save"
    Then I should see "h_clinton updated successfully."
    And I should see "analyst"
    And I should not see "committer"
    And I click the button with data-target "#roleModal_4"
    Then I wait for "1" seconds
    Then I should see "Edit User D_drumph"
    Then I check "analyst"
    Then I check "committer"
    Then I click "Save"
    Then I should see "d_drumph updated successfully."
    Then I should see "analyst, committer"


  @javascript
  Scenario: A manager can edit members subordinate manager teams on users page.
    Given a user with id "2" has a role "manager" and is logged in
    And the following users exist
      | id | email                | cvs_username  | display_name        | parent_id | cec_username |
      | 3  | hclinton@email.com   | h_clinton     | Hillary Clinton     | 2         | h_clinton    |
      | 4  | dtrump@email.com     | d_drumph      | Donald Trump        | 2         | d_drumph     |
      | 5  | gjohns@email.com     | g_johnson     | Gary Johnson        |           | g_johnson    |
      | 6  | tbeary@email.com     | t_bear        | Teddy Bear          | 3         | t_bear       |

    And the following roles exist:
      | role           |
      | analyst        |
      | committer      |

    And  I goto "/users"
    And  I should see "h_clinton"
    Then I click the button with data-target "#roleModal_3"
    Then I wait for "1" seconds
    Then I should see "Edit User H_clinton"
    Then I check "manager"
    Then I click "Save"
    Then I should see "h_clinton updated successfully."
    Then I wait for "3" seconds
    And  I goto "/users"
    And  I click "#add_user_button_3"
    And  "Hillary Clinton (h_clinton)" should not be in the "users_for_3" dropdown list
    And  I select "Gary Johnson (g_johnson)" from "users_for_3"
    Then I click "Add User"
    Then I should see "g_johnson successfully added"



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
    Given I fill in "user_search_name" with "CAR"
    When I hit enter within "#user_search_name"
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
    When I goto "/users"
    Given I fill in "user_search_name" with "CAR"
    When I hit enter within "#user_search_name"
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
    When I goto "/users"
    Given I fill in "user_search_name" with "CAR"
    When I hit enter within "#user_search_name"
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
    When I goto "/users"
    Given I fill in "user_search_name" with "CAR"
    When I hit enter within "#user_search_name"
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
    When I goto "/users"
    Given I fill in "user_search_name" with "CAR"
    When I hit enter within "#user_search_name"
    Then I see a user_searches result for name "email1@cisco.com"
    And I see a user_searches result for name "email2@cisco.com"
    And I do not see a user_searches result for name "email3@cisco.com"
    And I do not see a user_searches result for name "email4@cisco.com"


  @javascript
  Scenario: An admin user can view Delayed Jobs Management
    Given a user with role "admin" exists and is logged in
      And I goto "/admin/delayed_job"
      Then I should see "Overview"
      And I should see "Enqueued Jobs"


  @javascript @poltergeist @allow-rescue
  Scenario: A non admin user cannot view Delayed Jobs Management
    Given a user with role "webcat user" exists and is logged in
    And I goto "/admin/delayed_job"
    Then I should receive a "404" status



  ### Scenarios User Role access ###

# The /admin route is no longer valid.  We could re-write this for /escalations/admin
#  @javascript
#  Scenario: An Admin user should be able to get to the admin section
#    Given a user with role "admin" exists and is logged in
#    And I wait for "3" seconds
#    And I go to "/admin"
#    Then I should see "Admin Page"
#
#
#  @javascript
#  Scenario: An non Admin user should not be able to get to the admin section
#    Given a user with role "analyst" exists and is logged in
#    And I wait for "3" seconds
#    And I go to "/admin"
#    Then I should not see "Admin Page"
#    And I should see "You are not authorized"

