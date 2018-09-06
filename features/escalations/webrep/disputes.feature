Feature: Disputes
  In order to interact with disputes
  as a user
  I will provide ways to interact with disputes

  @javascript
  Scenario: a user can see data in the Submitter Type column
    Given a user with role "admin" exists and is logged in
    Then I goto "escalations/webrep/"
    When I trigger-click "#table-show-columns-button"
    And I trigger-click "#submitter-type-checkbox"
    When I trigger-click "#table-show-columns-button"
    Then I should see header with id "submitter-type"
    Then take a screenshot
