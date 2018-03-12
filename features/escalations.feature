Feature: Escalations
  In order to import, create or edit escalation bugs
  as a user
  I will provides ways to interact with escalation bugs

  @javascript
  Scenario: the appropriate canned response is added when manually resolving the bug

    Given a user with commit permission exists and is logged in
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product     | component    | description       | committer_id |
      | 222222 | 222222      | OPEN  | 1       | [BP][NSS] fixed bug | Escalations | TAC          | test description3 |     1        |
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
    Then I select "COMPLETED" from "bug[state]"
    And I select "P2" from "bug[priority]"
    And I wait for "2" seconds
    Then I should see "State Comment"
    And the textarea with id "state_comment" should have a value of "Coverage has not been updated."
