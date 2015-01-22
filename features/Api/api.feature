Feature: API Json interface
  In order to blank
  as a user
  I will provide

  Scenario: Request is Unauthorized when header does not contain credentials
    Given I goto "/api/v1/bugs"
    Then I should see "401 Unauthorized"

  @javascript
  Scenario: Request passes when header contains proper auth
    Given a "basic" user exists
    And I send authenticated headers to the api request "/api/v1/bugs"
    Then I should see "bugs"

  Scenario:

