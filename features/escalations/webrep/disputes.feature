Feature: Disputes
  In order to interact with disputes
  as a user
  I will provide ways to interact with disputes

  @javascript
  Scenario: a user visits the duplicate cases tab and sees a table of duplicate cases
    Given a user with role "webrep user" exists and is logged in
    Given the following disputes exist and have entries:
    |id|
    |1 |
    Given a dispute exists and is related to disputes with ID, '1':
    And I go to "/escalations/webrep/disputes/1"
    Then I click "#related-tab-link"
    Then take a screenshot
    Then I should see "0000000002"
