Feature: Disputes
  In order to interact with disputes
  as a user
  I will provide ways to interact with disputes

  @javascript
  Scenario: a user can see data in the Submitter Type column
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |id|submitter_type|
      |1 |CUSTOMER      |
    Then I goto "escalations/webrep/"
    When I trigger-click "#table-show-columns-button"
    And I trigger-click "#submitter-type-checkbox"
    Then I should see header with id "submitter-type"
    Then I should see "CUSTOMER"

