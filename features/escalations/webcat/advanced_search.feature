Feature: WebCat Advanced Search

  Background:
    Given a guest company exists

  @javascript
  Scenario: I perform an advanced search on all "PENDING" and "COMPLETE" entries
    Given a user with role "webcat user" exists and is logged in
    Given the following complaint entries exist:
    | id | status        |
    | 1  | PENDING       |
    | 2  | COMPLETED      |
    | 3  | NEW           |
    When I go to "/escalations/webcat/complaints"
    And I click "#advanced-search-button"
    And I fill in selectized of element "#status-input" with "['COMPLETED','PENDING']"
    And I click "#submit-advanced-search"
    And I wait for "4" seconds
    Then I should see tr element with id "1"
    Then I should see tr element with id "2"
    Then I should not see tr element with id "3"

