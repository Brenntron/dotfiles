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