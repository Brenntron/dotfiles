Feature: User Accounts
  In order to provide account services
  As a user
  I want to provide user authentication

  @javascript
  Scenario: A user with proper credentials should get logged in
    Given a user exists
    And I visit the root url
    And I should see "Please wait while we sign you in"
    Then I wait for "3" seconds
    And I should not see "Please wait while we sign you in"


  @javascript
  Scenario: A non-manager user can go to the users index page and see only their co-workers.
            Assigned bugs should be on users show page.
            A non-manager cannot get to the relationships section.
    Given a user exists and is logged in
    And the following users exist
      | id | email                | cvs_username | display_name        |
      | 2  | rainbows@email.com   | rainbow_b    | Rainbow Brite       |
      | 3  | hclinton@email.com   | h_clinton    | Hillary Clinton     |
      | 4  | dtrump@email.com     | d_drumph     | Donald Trump        |

    And the following relationships exist:
      | user_id | team_member_id |
      | 2       | 3              |
      | 2       | 1              |

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
  Scenario: A manager user can go to the users index page and see only their co-workers and team members.
            A manager can access the relationships page.
    Given a manager exists and is logged in
    And the following users exist
      | id | email                | cvs_username | display_name        |
      | 2  | rainbows@email.com   | rainbow_b    | Rainbow Brite       |
      | 3  | hclinton@email.com   | h_clinton    | Hillary Clinton     |
      | 4  | dtrump@email.com     | d_drumph     | Donald Trump        |

    And the following relationships exist:
      | user_id | team_member_id |
      | 2       | 3              |
      | 2       | 1              |
      | 1       | 3              |
      | 1       | 4              |

    And the following bugs exist:
      | id      | bugzilla_id | state  | user_id | summary             | product | component   | version | description       |
      |222222   | 222222      | OPEN   | 3       | [BP][NSS] fixed bug | Research| Snort Rules | 2.6.0   | test description3 |
      |333333   | 333333      | OPEN   | 1       | [TELUS] broken bug  | Research| Snort Rules | 2.6.0   | test description4 |

    Then I wait for "3" seconds
    And  I goto "/users"
    And  I should see "h_clinton"
    And  I should see "d_drumph"
    And  I should not see "rainbow_b"
    Then I goto "/users/1/relationships"
    And  I should see "d_drumph"

  @javascript
  Scenario: A manager can add and remove team members on the relationships page.
    Given a manager exists and is logged in
    And the following users exist
      | id | email                | cvs_username  | display_name        |
      | 2  | rainbows@email.com   | rainbow_b     | Rainbow Brite       |
      | 3  | hclinton@email.com   | h_clinton     | Hillary Clinton     |
      | 4  | dtrump@email.com     | d_drumph      | Donald Trump        |
      | 5  | gjohns@email.com     | g_johnson     | Gary Johnson        |
      | 6  | tbeary@email.com     | t_bear        | Teddy Bear          |

    And the following relationships exist:
      | user_id | team_member_id |
      | 2       | 3              |
      | 2       | 6              |
      | 1       | 3              |

    Then I wait for "3" seconds
    And  I goto "/users/1/relationships"
    And  I should see "h_clinton"
    And  "Hillary Clinton (h_clinton)" should not be in the dropdown list
    And  I select "Donald Trump (d_drumph)" from "relationship_team_member_id"
    Then I click "Add"
    Then I should see "d_drumph is now on your team!"
    And  I select "Teddy Bear (t_bear)" from "relationship_team_member_id"
    Then I should see "Teddy Bear (t_bear) is on a team already. Users can be members of multiple teams."
    Then I click "Ok"
    Then I click "Add"
    And  I should see "t_bear is now on your team!"

  @javascript
  Scenario: A manager user can go to a users show page and update their metrics timeframe preference.
    Given a manager exists and is logged in
    And the following users exist
      | id | email                | cvs_username | display_name        |
      | 2  | rainbows@email.com   | rainbow_b    | Rainbow Brite       |
      | 3  | hclinton@email.com   | h_clinton    | Hillary Clinton     |
      | 4  | dtrump@email.com     | d_drumph     | Donald Trump        |

    And the following relationships exist:
      | user_id | team_member_id |
      | 1       | 3              |
      | 1       | 4              |

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
      | id | email                | cvs_username | display_name        |
      | 3  | hclinton@email.com   | h_clinton    | Hillary Clinton     |

    And the following relationships exist:
      | user_id | team_member_id |
      | 1       | 3              |

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
  Scenario: A user can search using email
    Given a user exists and is logged in
    And I wait for "3" seconds
    And the following users exist
      | email              |
      | carlzipp@cisco.com |
      | davecarr@cisco.com |
      | porsche@cisco.com  |
      | bentley@cisco.com  |
    When I goto "/users"
    Then I should see a user search form
    Given I fill in "Name" with "CAR"
    When I click button "Search"
    Then I see a user_searches result for name "carlzipp@cisco.com"
    And I see a user_searches result for name "davecarr@cisco.com"
    And I do not see a user_searches result for name "porsche@cisco.com"
    And I do not see a user_searches result for name "bentley@cisco.com"

  @javascript
  Scenario: A user can search using a users display name
    Given a user exists and is logged in
    And I wait for "3" seconds
    And the following users exist
      | email            | display_name        |
      | email1@cisco.com | Carl Zipp           |
      | email2@cisco.com | David Carr          |
      | email3@cisco.com | Porsche Bugatti     |
      | email4@cisco.com | Bentley Ford        |
    Given I goto "/users"
    Given I fill in "Name" with "CAR"
    When I click button "Search"
    Then I see a user_searches result for name "Carl Zipp"
    And I see a user_searches result for name "David Carr"
    And I do not see a user_searches result for name "Porsche Bugatti"
    And I do not see a user_searches result for name "Bentley Ford"

  @javascript
  Scenario: A user can search using CVS user name
    Given a user exists and is logged in
    And I wait for "3" seconds
    And the following users exist
      | email            | cvs_username |
      | email1@cisco.com | carlzipp     |
      | email2@cisco.com | davecarr     |
      | email3@cisco.com | porsche      |
      | email4@cisco.com | bentley      |
    Given I goto "/users"
    Given I fill in "Name" with "CAR"
    When I click button "Search"
    Then I see a user_searches result for name "carlzipp"
    And I see a user_searches result for name "davecarr"
    And I do not see a user_searches result for name "porsche"
    And I do not see a user_searches result for name "bentley"

  @javascript
  Scenario: A user can search using CEC username
    Given a user exists and is logged in
    And I wait for "3" seconds
    And the following users exist
      | email            | cec_username |
      | email1@cisco.com | carlzipp     |
      | email2@cisco.com | davecarr     |
      | email3@cisco.com | porsche      |
      | email4@cisco.com | bentley      |
    Given I goto "/users"
    Given I fill in "Name" with "CAR"
    When I click button "Search"
    Then I see a user_searches result for name "carlzipp"
    And I see a user_searches result for name "davecarr"
    And I do not see a user_searches result for name "porsche"
    And I do not see a user_searches result for name "bentley"

  @javascript
  Scenario: A user can search using Kerberos Login
    Given a user exists and is logged in
    And I wait for "3" seconds
    And the following users exist
      | email            | kerberos_login |
      | email1@cisco.com | carlzipp       |
      | email2@cisco.com | davecarr       |
      | email3@cisco.com | porsche        |
      | email4@cisco.com | bentley        |
    Given I goto "/users"
    Given I fill in "Name" with "CAR"
    When I click button "Search"
    Then I see a user_searches result for name "carlzipp"
    And I see a user_searches result for name "davecarr"
    And I do not see a user_searches result for name "porsche"
    And I do not see a user_searches result for name "bentley"

