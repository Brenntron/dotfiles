Feature: UserSearch
  Tests for user search

#    Then take a photo

  @javascript
  Scenario: A user can search
    Given a user exists and is logged in
    And I wait for "3" seconds
    And the following users exist
      | email                | cvs_username | display_name        |
      | carlzipp@cisco.com   | carlzipp     | Carl Zipp           |
      | davecarr@cisco.com   | davecarr     | David Carr          |
      | pbugatti@cisco.com   | porsche      | Porsche Bugatti     |
      | bentford@cisco.com   | bentley      | Bentley Ford        |
    When I goto "/user_searches/new"
    Then I see a user_searches new form
    Given I fill in "Name" with "car"
    When I click button "Search"
    Then I see a user_searches result for name "carlzipp"
    And I see a user_searches result for name "davecarr"
    And I do not see a user_searches result for name "porsche"
    And I do not see a user_searches result for name "bentley"

