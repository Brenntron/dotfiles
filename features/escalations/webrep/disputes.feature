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
    Then Element with class "sorting" should have content "Submitter Type"
#    Then I should see "Submitter Type"
    Then take a screenshot