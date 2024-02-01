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
    And that Complaint Ticket should have an assignee of current user

  @javascript
  Scenario: a user tries to take multiple tickets, some of which are already assigned
    Given a user with role "webcat user" exists and is logged in
    And the following users exist
      | id | cvs_username | cec_username | display_name |
      | 2  | test_user    | test_user    | test_user    |

    And the following complaints exist:
      | channel       | id |
      | talosintel    | 1  |
      | talosintel    | 2  |
      | talosintel    | 3  |
      | talosintel    | 4  |
      | wbnp          | 5  |
      | wbnp          | 6  |
      | wbnp          | 7  |
      | internal      | 8  |
      | internal      | 9  |

    And the following complaint entries exist:
      | uri            | domain          | entry_type | complaint_id | status     | user_id|
      | abc.com        | abc.com         | URI/DOMAIN |  1           | NEW        |        |
      | whatever.com   | whatever.com    | URI/DOMAIN |  2           | NEW        |        |
      | url.com        | url.com         | URI/DOMAIN |  3           | ASSIGNED   |    2   |
      | test.com       | test.com        | URI/DOMAIN |  4           | ASSIGNED   |    2   |
      | something.com  | something.com   | URI/DOMAIN |  5           | NEW        |        |
      | yadayada.com   | yadayada.com    | URI/DOMAIN |  6           | NEW        |        |
      | nothing.com    | nothing.com     | URI/DOMAIN |  7           | ASSIGNED   |    2   |
      | something.com  | something.com   | URI/DOMAIN |  8           | NEW        |        |
      | blahblah.com   | blahblah.com    | URI/DOMAIN |  9           | ASSIGNED   |    2   |
    And I goto "/escalations/webcat/complaints?f=ALL"
    Then I click "#complaints_select_all"
    And I wait for "3" seconds
    Then I click ".take-ticket-toolbar-button"
    And I wait for "15" seconds
    And I should see "Currently assigned to someone else - 3, 4, 7, and 9"


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
    And that Complaint Ticket should not have an assignee of current user

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
    Then that Complaint Ticket should not have an assignee of current user

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
    And that Complaint Ticket should not have an assignee of current user

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


# TODO
#  Scenario: a user can take multiple selected entries
#  Scenario: a user can return multiple selected entries

#  Scenario: a manager can assign a user to a complaint
#  Scenario: a manager can assign a user to multiple complaints
#  Scenario: a manager can assign a user as a reviewer to a complaint
#  Scenario: a manager can assign a user as a second reviewer to a complaint
#  Scenario: a manager can unassign an assignee from a complaint
#  Scenario: a manager can unassign a reviewer from a complaint
#  Scenario: a manager can unassign a second reviewer from a complaint
#  Scenario: a manager cannot assign the same user as assignee and reviewer on a complaint

#  Scenario: a non-manager can unassign a user from a complaint
#  Scenario: a non-manager cannot unassign a reviewer from a complaint
#  Scenario: a non-manager cannot unassign a second reviewer from a complaint
#  Scenario: a non-manager cannot assign a user other than themself to a complaint
#  Scenario: a non-manager cannot assign a user other than themself as a reviewer to a complaint
#  Scenario: a non-manager cannot assign a user other than themself as a second reviewer to a complaint

#  Scenario: a user cannot change the reviewer on a COMPLETED entry
#  Scenario: a user cannot change the second reviewer on a COMPLETED entry
