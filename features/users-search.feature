Feature: UserSearch
  Tests for user search

#    Then take a photo

  @javascript
  Scenario: A user can search
    Given a user exists and is logged in
    And I wait for "3" seconds
    And the following users exist
      | email            | display_name        |
      | email1@cisco.com | Carl Zipp           |
      | email2@cisco.com | David Carr          |
      | email3@cisco.com | Porsche Bugatti     |
      | email4@cisco.com | Bentley Ford        |
    When I goto "/user_searches/new"
    Then I see a user_searches form
    Given I fill in "Name" with "CAR"
    When I click button "Search"
    Then I see a user_searches result for name "Carl Zipp"
    And I see a user_searches result for name "David Carr"
    And I do not see a user_searches result for name "Porsche Bugatti"
    And I do not see a user_searches result for name "Bentley Ford"

  @javascript
  Scenario: A user can search
    Given a user exists and is logged in
    And I wait for "3" seconds
    And the following users exist
      | email            | cvs_username |
      | email1@cisco.com | carlzipp     |
      | email2@cisco.com | davecarr     |
      | email3@cisco.com | porsche      |
      | email4@cisco.com | bentley      |
    When I goto "/user_searches/new"
    Then I see a user_searches form
    Given I fill in "Name" with "CAR"
    When I click button "Search"
    Then I see a user_searches result for name "carlzipp"
    And I see a user_searches result for name "davecarr"
    And I do not see a user_searches result for name "porsche"
    And I do not see a user_searches result for name "bentley"

  @javascript
  Scenario: A user can search
    Given a user exists and is logged in
    And I wait for "3" seconds
    And the following users exist
      | email            | cec_username |
      | email1@cisco.com | carlzipp     |
      | email2@cisco.com | davecarr     |
      | email3@cisco.com | porsche      |
      | email4@cisco.com | bentley      |
    When I goto "/user_searches/new"
    Then I see a user_searches form
    Given I fill in "Name" with "CAR"
    When I click button "Search"
    Then I see a user_searches result for name "carlzipp"
    And I see a user_searches result for name "davecarr"
    And I do not see a user_searches result for name "porsche"
    And I do not see a user_searches result for name "bentley"

  @javascript
  Scenario: A user can search
    Given a user exists and is logged in
    And I wait for "3" seconds
    And the following users exist
      | email            | kerberos_login |
      | email1@cisco.com | carlzipp       |
      | email2@cisco.com | davecarr       |
      | email3@cisco.com | porsche        |
      | email4@cisco.com | bentley        |
    When I goto "/user_searches/new"
    Then I see a user_searches form
    Given I fill in "Name" with "CAR"
    When I click button "Search"
    Then I see a user_searches result for name "carlzipp"
    And I see a user_searches result for name "davecarr"
    And I do not see a user_searches result for name "porsche"
    And I do not see a user_searches result for name "bentley"

  @javascript
  Scenario: A user can search
    Given a user exists and is logged in
    And I wait for "3" seconds
    And the following users exist
      | email              |
      | carlzipp@cisco.com |
      | davecarr@cisco.com |
      | porsche@cisco.com  |
      | bentley@cisco.com  |
    When I goto "/user_searches/new"
    Then I see a user_searches form
    Given I fill in "Name" with "CAR"
    When I click button "Search"
    Then I see a user_searches result for name "carlzipp@cisco.com"
    And I see a user_searches result for name "davecarr@cisco.com"
    And I do not see a user_searches result for name "porsche@cisco.com"
    And I do not see a user_searches result for name "bentley@cisco.com"

