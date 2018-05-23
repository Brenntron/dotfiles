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

  @javascript
  Scenario:A summary must be provided to create a new research bug
    Given a user with commit permission exists and is logged in
    And the following bugs exist:
      | id | bugzilla_id | state | user_id | summary                                     | product  | component   | description       | committer_id |
      | 111111 | 111111      | OPEN  | 1       | test escalation summary                     | Escalations | TAC | test description  | 1                   |
    And the following roles exist:
      | role           |
      | admin          |

    And a user with id "1" has a role of "admin"
    Then I wait for "3" seconds
    And  I goto "/escalations/bugs/111111"
    When I click "create_new_research_button"
    When I click "OK"
    Then I should see "must provide a new summary line for the new research bug."

  @javascript
  Scenario: A description must be provided to create a new research bug
    Given a user with commit permission exists and is logged in
    And the following bugs exist:
      | id | bugzilla_id | state | user_id | summary                                     | product  | component   | description       | committer_id |
      | 111111 | 111111      | OPEN  | 1       | test escalation summary                     | Escalations | TAC | test description  | 1                   |
    And the following roles exist:
      | role           |
      | admin          |

    And a user with id "1" has a role of "admin"
    Then I wait for "3" seconds
    And  I goto "/escalations/bugs/111111"
    When I click "create_new_research_button"
    And  I fill in "new_summary_line" with "New Bug Summary"
    When I click "OK"
    Then I wait for "1" seconds
    Then I should see "must provide a description for the new research bug."

  @javascript
  Scenario: Cannot create a research bug when one bug blocks another
    Given a user with commit permission exists and is logged in
    And the following bugs exist:
      | id | bugzilla_id | state | user_id | summary                                     | product  | component   | description       | committer_id |
      | 111111 | 111111      | OPEN  | 1       | test escalation summary                     | Escalations | TAC | test description  | 1                   |
      | 222222 | 222222      | OPEN  | 1       | test escalation summary                     | Research | Snort Rules | test description  | 1                   |
    And the following roles exist:
      | role           |
      | admin          |

    And a user with id "1" has a role of "admin"
    Then I wait for "3" seconds
    Then I relate 111111 to 222222 with block
    And  I goto "/escalations/bugs/111111"
    And  I should not see "Create New Research Bug"

  @javascript
  Scenario: A research bug should block an escalation bug
    #TODO: write this test
    
  @javascript
  Scenario: Notes are copied from an escalation to a research bug
    #TODO: write this test