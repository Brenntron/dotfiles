Feature: Escalations
  In order to import, create or edit escalation bugs
  as a user
  I will provides ways to interact with escalation bugs

  @javascript
  Scenario: A summary must be provided to create a new research bug
    Then pending
    Given a user with role "ips escalator" exists and is logged in
    And the following "escalation_bug" bugs with trait "open_bug" exist:
      | id  | bugzilla_id | user_id | summary                 | description       | committer_id |
      | 111 | 111111      | 1       | test escalation summary | test description  | 1            |

    Then I wait for "3" seconds
    And  I goto "/escalations/bugs/111"
    When I click "create_new_research_button"
    When I click "OK"
    Then I should see "must provide a new summary line for the new research bug."

  @javascript
  Scenario: A description must be provided to create a new research bug
    Then pending
    Given a user with commit permission exists and is logged in
    And the following "escalation_bug" bugs with trait "open_bug" exist:
      |   id   | bugzilla_id | user_id | summary                 | description       | committer_id |
      | 111111 |    111111   | 1       | test escalation summary | test description  | 1            |
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
  Scenario: A research bug should block an escalation bug
    #TODO: write this test
    Then pending

  @javascript
  Scenario: Notes are copied from an escalation to a research bug
    #TODO: write this test
    Then pending
