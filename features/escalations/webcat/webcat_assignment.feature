Feature: Webcat complaint entry assignment

  ### ASSIGNMENT FUNCTIONS ###
  @javascript
  Scenario: a user can take (assign self to) a complaint
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type | status     |
      | 1  | abc.com        | abc.com         | URI/DOMAIN | NEW        |
    And  I goto "/escalations/webcat/complaints"
    And  I wait for "3" seconds
    And  I should not see "ASSIGNED"
    And  I click ".cat-index-main-row"
    And  I click ".take-ticket-toolbar-button"
    Then I wait for "3" seconds
    Then I should see "ASSIGNED"

  @javascript
  Scenario: a user can return (unassign self from) a complaint
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type | status     |
      | 1  | abc.com        | abc.com         | URI/DOMAIN | NEW        |
    And  I goto "/escalations/webcat/complaints"
    And  I wait for "3" seconds
    And  I should not see "ASSIGNED"
    And  I click ".cat-index-main-row"
    And  I click ".take-ticket-toolbar-button"
    Then I wait for "3" seconds
    Then I should see "ASSIGNED"
    And  I click ".return-ticket-toolbar-button"
    Then I wait for "8" seconds
    And  I should not see "ASSIGNED"
    And  I should see "Vrt Incoming"

  @javascript
  Scenario: a user cannot take (assign self to) a complaint that is assigned to another user
    Given a user with role "webcat user" exists and is logged in
    And the following users exist
      | id | cvs_username | cec_username | display_name |
      | 3  | test_user    | test_user    | test_user    |
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type | status     | user_id |
      | 1  | abc.com        | abc.com         | URI/DOMAIN | ASSIGNED   |    3    |
    And  I goto "/escalations/webcat/complaints"
    And  I wait for "3" seconds
    And  I click ".cat-index-main-row"
    And  I click ".take-ticket-toolbar-button"
    Then I wait for "3" seconds
    And  I should see "ERROR TAKING ENTRIES"
    And  I should see "Currently assigned to someone else"

  @javascript
  Scenario: a user cannot return (unassign self from) a complaint that is assigned to another user
    Given a user with role "webcat user" exists and is logged in
    And the following users exist
      | id | cvs_username | cec_username | display_name |
      | 3  | test_user    | test_user    | test_user    |
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type | status     | user_id |
      | 1  | abc.com        | abc.com         | URI/DOMAIN | ASSIGNED   |    3    |
    And  I goto "/escalations/webcat/complaints"
    And  I wait for "3" seconds
    And  I click ".cat-index-main-row"
    And  I click ".return-ticket-toolbar-button"
    Then I wait for "3" seconds
    And  I should see "ERROR RETURNING ENTRIES"
    And  I should see "Currently assigned to someone else"

  @javascript
  Scenario: a user cannot return (unassign self from) a complaint that has not been assigned to anyone
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type | status |
      | 1  | abc.com        | abc.com         | URI/DOMAIN | NEW    |
    And  I goto "/escalations/webcat/complaints"
    And  I wait for "3" seconds
    And  I click ".cat-index-main-row"
    And  I click ".return-ticket-toolbar-button"
    Then I wait for "3" seconds
    And  I should see "ERROR RETURNING ENTRIES"
    And  I should see "Not yet assigned"

  @javascript
  Scenario: a user cannot take a complaint that is in COMPLETED state
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type | status    |
      | 1  | abc.com        | abc.com         | URI/DOMAIN | COMPLETED |
    And  I goto "/escalations/webcat/complaints"
    And  I wait for "3" seconds
    And  I click ".cat-index-main-row"
    And  I click ".take-ticket-toolbar-button"
    Then I wait for "3" seconds
    And  I should see "ERROR TAKING ENTRIES"
    And  I should see "Already completed"


  @javascript
  Scenario: a user can assign themself as a (first) reviewer on a complaint
    Given a user with role "webcat user" exists and is logged in
    And the following users exist
      | id | cvs_username | cec_username | display_name |
      | 3  | test_user    | test_user    | test_user    |
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type | status     | user_id |
      | 1  | abc.com        | abc.com         | URI/DOMAIN | ASSIGNED   |    3    |
    And  I goto "/escalations/webcat/complaints"
    And  I wait for "3" seconds
    And  I click "#assignment-type-reviewer"
    And  I click ".cat-index-main-row"
    And  I click ".take-ticket-toolbar-button"
    Then I wait for "3" seconds
    And  I should not see "ERROR TAKING ENTRIES"

  @javascript
  Scenario: a user can return a ticket as a (first) reviewer on a complaint
    Given a user with role "webcat user" exists and is logged in
    And the following users exist
      | id | cvs_username | cec_username | display_name |
      | 3  | test_user    | test_user    | test_user    |
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type | status     | user_id | reviewer_id |
      | 1  | abc.com        | abc.com         | URI/DOMAIN | ASSIGNED   |    3    |     1       |
    And  I goto "/escalations/webcat/complaints"
    And  I wait for "3" seconds
    And  I click "#assignment-type-reviewer"
    And  I click ".cat-index-main-row"
    And  I click ".return-ticket-toolbar-button"
    Then I wait for "3" seconds
    And  I should not see "ERROR RETURNING ENTRIES"

  @javascript
  Scenario: a user cannot assign themself as a (first) reviewer on a complaint where they are the assignee
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type | status     | user_id |
      | 1  | abc.com        | abc.com         | URI/DOMAIN | ASSIGNED   |    1    |
    And  I goto "/escalations/webcat/complaints"
    And  I wait for "3" seconds
    And  I click "#assignment-type-reviewer"
    And  I click ".cat-index-main-row"
    And  I click ".take-ticket-toolbar-button"
    Then I wait for "3" seconds
    And I should see "ERROR TAKING ENTRIES"
    And I should see "Assignee cannot also be a Reviewer"

  @javascript
  Scenario: a user can assign themself as a second reviewer on a complaint
    Given a user with role "webcat user" exists and is logged in
    And the following users exist
      | id | cvs_username | cec_username | display_name  |
      | 3  | test_user    | test_user    | Linda Belcher |
      | 4  | tina_belcher | tina_belcher | Tina Belcher  |
    And the following complaint entries exist:
      | id | uri          | domain    | entry_type | status     | user_id | reviewer_id |
      | 1  | abc.com      | abc.com   | URI/DOMAIN | ASSIGNED   |    3    |      4      |
    And  I goto "/escalations/webcat/complaints"
    And  I wait for "3" seconds
    And  I click "#assignment-type-second-reviewer"
    And  I click ".cat-index-main-row"
    And  I click ".take-ticket-toolbar-button"
    Then I wait for "3" seconds
    And  I should not see "ERROR TAKING ENTRIES"

  @javascript
  Scenario: a user cannot assign themself as a second reviewer on a complaint where they are the assignee
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type | status     | user_id |
      | 1  | abc.com        | abc.com         | URI/DOMAIN | ASSIGNED   |    1    |
    And  I goto "/escalations/webcat/complaints"
    And  I wait for "3" seconds
    And  I click "#assignment-type-second-reviewer"
    And  I click ".cat-index-main-row"
    And  I click ".take-ticket-toolbar-button"
    Then I wait for "3" seconds
    And I should see "ERROR TAKING ENTRIES"
    And I should see "Assignee cannot also be a Reviewer"

  @javascript
  Scenario: a user can return a ticket as a second reviewer on a complaint
    Given a user with role "webcat user" exists and is logged in
    And the following users exist
      | id | cvs_username | cec_username | display_name |
      | 3  | test_user    | test_user    | test_user    |
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type | status     | user_id | second_reviewer_id |
      | 1  | abc.com        | abc.com         | URI/DOMAIN | ASSIGNED   |    3    |     1       |
    And  I goto "/escalations/webcat/complaints"
    And  I wait for "3" seconds
    And  I click "#assignment-type-second-reviewer"
    And  I click ".cat-index-main-row"
    And  I click ".return-ticket-toolbar-button"
    Then I wait for "3" seconds
    And  I should not see "ERROR RETURNING ENTRIES"


#  @javascript
#  Scenario: a manager can assign a user to a complaint
