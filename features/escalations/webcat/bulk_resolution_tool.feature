Feature: WebCat Bulk Resolution Tool
  Rule: The Bulk Resolution Tool button only enables when a submittable row is selected

    @javascript
    Scenario: a webcat user selects one non-pending entry
      Given a user with role "webcat user" exists and is logged in
      And the following complaint entries exist:
        | id | resolution | status    |
        | 1  | FIXED      | PENDING   |
        | 2  |            | COMPLETED |
        | 3  |            | NEW       |
        | 4  |            | ASSIGNED  |
      When I go to "/escalations/webcat/complaints"
      And I click row with id "1"
      Then button with id "index_update_resolution" should be disabled

    @javascript
    Scenario: a webcat user selects multiple non-pending entry
      Given a user with role "webcat user" exists and is logged in
      And the following complaint entries exist:
        | id | resolution | status    |
        | 1  | FIXED      | PENDING   |
        | 2  |            | COMPLETED |
        | 3  |            | NEW       |
        | 4  |            | ASSIGNED  |
      When I go to "/escalations/webcat/complaints"
      When I click row with id "3"
      And I click row with id "4"
      And take a screenshot
      Then button with id "index_update_resolution" should be enabled
      When I click row with id "2"
      Then button with id "index_update_resolution" should be enabled
      When I click row with id "1"
      Then button with id "index_update_resolution" should be enabled
