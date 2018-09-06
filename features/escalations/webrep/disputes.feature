Feature: Disputes
  In order to interact with disputes
  as a user
  I will provide ways to interact with disputes

  @javascript
  Scenario: the last submitted field returns data
    Given a user with role "admin" exists and is logged in
    And the following disputes exist and have entries:
    |id|
    |1 |
    And the following disputes exist and have entries:
    |id|
    |2 |
    Then I go to "/escalations/webrep/disputes/1"
    Then I click link "Research"
    Then take a screenshot
    Then Expect date in element "#last-submitted" to equal today's date

