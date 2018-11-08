Feature: Escalations
  In order to import, create or edit escalation bugs
  as a user
  I will provides ways to interact with escalation bugs

  @javascript
  Scenario: the appropriate canned response is added when manually resolving the bug

    Given a user with commit permission exists and is logged in
    And the following "escalation_bug" bugs with trait "open_bug" exist:
      | id     | bugzilla_id | user_id | summary             | description       | committer_id |
      | 222222 |    222222   |    1    | [BP][NSS] fixed bug | test description3 |     1        |
    And the following roles exist:
      | role           |
      | admin          |
    #until we open to public
    And a user with id "1" has a role of "admin"
    Then I wait for "2" seconds
    And I goto "/escalations/bugs/222222"
    Then I click the span with data-target "#editBug"
    And I wait for "1" seconds
    Then I should not see "State Comment"
    Then I select "COMPLETED" from "bug-form-state-input"
    And I select "P2" from "bug-form-priority-input"
    And I wait for "2" seconds
    Then I should see "State Comment"
    And the textarea with id "state_comment" should have a value of "Coverage has not been updated."

  @javascript
  Scenario: Cannot create a research bug when one bug blocks another
    Given a user with commit permission exists and is logged in
    And the following "escalation_bug" bugs with trait "open_bug" exist:
      |   id   | bugzilla_id | user_id | summary                 | description       | committer_id |
      | 111111 | 111111      | 1       | test escalation summary | test description  | 1            |
    And the following "research_bug" bugs with trait "open_bug" exist:
      |   id   | bugzilla_id | user_id | summary                 | description       | committer_id |
      | 222222 | 222222      | 1       | test research summary   | test description  | 1            |
    And the following roles exist:
      | role           |
      | admin          |

    And a user with id "1" has a role of "admin"
    Then I wait for "3" seconds
    Then I relate 111111 to 222222 with block
    And  I goto "/escalations/bugs/111111"
    And  I should not see "Create New Research Bug"
    
