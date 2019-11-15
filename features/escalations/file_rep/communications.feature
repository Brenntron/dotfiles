Feature: Filerep communications
  In order to communicate with filerep dispute customers
  I will provide a communications interface for filerep tickets


  @javascript
  Scenario: a user can view filerep email templates
    Given a user with role "filerep user" exists and is logged in
    And the following customers exist:
      |id| name            |
      |1 | Dispute Analyst |
    And vrtincoming exists
    And the following FileRep disputes exist:
      |id| sha256_hash                                                       |
      |11| 343518b26e0a872772808605f9f28aa75f64d86a6608e1347c979d033a72cb54  |
    And the following FileRep email templates exist:
      | template_name | description      |
      | Filerep Test  | I am only a test |
    And I goto "/escalations/file_rep/disputes/11"
    Then I click "Manage Email Templates"
    Then I should see "I am only a test"