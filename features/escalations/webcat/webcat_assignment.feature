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
    #Need to show User column - hidden by default
    And I click "#webcat-index-table-show-columns-button"
    And I click "#view-user-col-cb"
    And I click "#view-data-assignee-cb"
    And  I click ".cat-index-main-row"
    And  I click ".return-ticket-toolbar-button"
    Then I wait for "3" seconds
    And  I should see "ERROR RETURNING ENTRIES"
    And  I should see "No assignee"

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

  @javascript
  Scenario: a user can take multiple selected entries
    Given a user with role "webcat user" exists and is logged in
    And the following users exist
      | id | cvs_username | cec_username | display_name |
      | 2  | test_user    | test_user    | test_user    |
    And the following complaints exist:
      | channel       | id |
      | talosintel    | 1  |
      | talosintel    | 2  |
    And the following complaint entries exist:
      | uri            | domain          | entry_type | complaint_id | status     | user_id|
      | abc.com        | abc.com         | URI/DOMAIN |  1           | NEW        |        |
      | whatever.com   | whatever.com    | URI/DOMAIN |  2           | NEW        |        |
    And I goto "/escalations/webcat/complaints?f=ALL"
    Then I click "#complaints_select_all"
    And I wait for "3" seconds
    Then I click ".take-ticket-toolbar-button"
    And I wait for "15" seconds
    And that Complaint Ticket should have an assignee of current user
    And the last Complaint Ticket should have an assignee of current user

  @javascript
  Scenario: a user can return multiple selected entries
    Given a user with role "webcat user" exists and is logged in
    And the following users exist
      | id | cvs_username | cec_username | display_name |
      | 3  | test_user    | test_user    | test_user    |
    And the following complaint entries exist:
      | id | uri                 | domain          | entry_type | status     | user_id | second_reviewer_id |
      | 1  | abc.com             | abc.com         | URI/DOMAIN | ASSIGNED   |    3    |     1              |
      | 2  | whatever.com        | whatever.com    | URI/DOMAIN | ASSIGNED   |    3    |     1              |
    And  I goto "/escalations/webcat/complaints"
    And  I wait for "3" seconds
    And  I click "#assignment-type-second-reviewer"
    Then I click "#complaints_select_all"
    And  I click ".return-ticket-toolbar-button"
    And  I wait for "3" seconds
    And  I should not see "ERROR RETURNING ENTRIES"

  @javascript
  Scenario: a manager can assign a user to a complaint
    Given a user with role "webcat manager" exists and is logged in
    And the following users exist
      | id | cvs_username  | cec_username  | display_name   |
      | 2  | bob_belcher   | bob_belcher   | Bob Belcher    |
      | 3  | linda_belcher | linda_belcher | Linda Belcher  |
      | 4  | tina_belcher  | tina_belcher  | Tina Belcher   |
    And the following org_subsets exist:
      | id | name   |
      | 7  | webcat |
    And the following roles exist:
      | id | role        | org_subset_id |
      | 17 | webcat user |     7         |
    And a user with id "2" has a role of "webcat user"
    And a user with id "3" has a role of "webcat user"
    And a user with id "4" has a role of "webcat user"
    And the following complaint entries exist:
      | id    | uri                 | domain          | entry_type | status  |
      | 1111  | abc.com             | abc.com         | URI/DOMAIN | NEW     |
      | 2222  | whatever.com        | whatever.com    | URI/DOMAIN | NEW     |
    And  I goto "/escalations/webcat/complaints"
    And  I wait for "3" seconds
    #Need to show User column with Assignee data - hidden by default
    And I click "#webcat-index-table-show-columns-button"
    And I click "#view-user-col-cb"
    And I click "#view-data-assignee-cb"
    And I click row with id "1"
    And I click "#index_change_assign"
    And I wait for "1" seconds
    And I click "#index_target_assignee"
    And I click "#assignee_3"
    And I click "#button_reassign"
    And I wait for "1" seconds
    And I should see "Linda Belcher"

  @javascript
  Scenario: a manager can assign a user to multiple complaints
    Given a user with role "webcat manager" exists and is logged in
    And the following users exist
      | id | cvs_username  | cec_username  | display_name   |
      | 2  | bob_belcher   | bob_belcher   | Bob Belcher    |
      | 3  | linda_belcher | linda_belcher | Linda Belcher  |
      | 4  | tina_belcher  | tina_belcher  | Tina Belcher   |
    And the following org_subsets exist:
      | id | name   |
      | 7  | webcat |
    And the following roles exist:
      | id | role        | org_subset_id |
      | 17 | webcat user |     7         |
    And a user with id "2" has a role of "webcat user"
    And a user with id "3" has a role of "webcat user"
    And a user with id "4" has a role of "webcat user"
    And the following complaint entries exist:
      | id    | uri                 | domain          | entry_type | status  |
      | 1111  | abc.com             | abc.com         | URI/DOMAIN | NEW     |
      | 2222  | whatever.com        | whatever.com    | URI/DOMAIN | NEW     |
    And  I goto "/escalations/webcat/complaints"
    And  I wait for "3" seconds
    #Need to show User column with Assignee data - hidden by default
    And I click "#webcat-index-table-show-columns-button"
    And I click "#view-user-col-cb"
    And I click "#view-data-assignee-cb"
    And I click "#complaints_select_all"
    And I click "#index_change_assign"
    And I wait for "1" seconds
    And I click "#index_target_assignee"
    And I click "#assignee_3"
    And I click "#button_reassign"
    And I wait for "1" seconds
    And the first row of table "complaints-index" and col "users-col" should have content "Linda Belcher"
    And I should see element ".assignee-row" with text "Linda Belcher" a total of "2" times

  @javascript
  Scenario: a manager can assign a user as a reviewer to a complaint
    Given a user with role "webcat manager" exists and is logged in
    And the following users exist
      | id | cvs_username  | cec_username  | display_name   |
      | 2  | bob_belcher   | bob_belcher   | Bob Belcher    |
      | 3  | linda_belcher | linda_belcher | Linda Belcher  |
      | 4  | tina_belcher  | tina_belcher  | Tina Belcher   |
    And the following org_subsets exist:
      | id | name   |
      | 7  | webcat |
    And the following roles exist:
      | id | role        | org_subset_id |
      | 17 | webcat user |     7         |
    And a user with id "2" has a role of "webcat user"
    And a user with id "3" has a role of "webcat user"
    And a user with id "4" has a role of "webcat user"
    And the following complaint entries exist:
      | id    | uri                 | domain          | entry_type | status  |
      | 1111  | abc.com             | abc.com         | URI/DOMAIN | NEW     |
      | 2222  | whatever.com        | whatever.com    | URI/DOMAIN | NEW     |
    And  I goto "/escalations/webcat/complaints"
    And  I wait for "3" seconds
    #Need to show User column with Reviewer data - hidden by default
    And I click "#webcat-index-table-show-columns-button"
    And I click "#view-user-col-cb"
    And I click "#view-data-reviewer-cb"
    And I click row with id "1"
    And I click "#assignment-type-reviewer"
    And I click "#index_change_assign"
    And I wait for "1" seconds
    And I click "#index_target_assignee"
    And I click "#assignee_3"
    And I click "#button_reassign"
    And I wait for "1" seconds
    And I should see "Linda Belcher"

  @javascript
  Scenario: a manager can assign a user as a second reviewer to a complaint
    Given a user with role "webcat manager" exists and is logged in
    And the following users exist
      | id | cvs_username  | cec_username  | display_name   |
      | 2  | bob_belcher   | bob_belcher   | Bob Belcher    |
      | 3  | linda_belcher | linda_belcher | Linda Belcher  |
      | 4  | tina_belcher  | tina_belcher  | Tina Belcher   |
    And the following org_subsets exist:
      | id | name   |
      | 7  | webcat |
    And the following roles exist:
      | id | role        | org_subset_id |
      | 17 | webcat user |     7         |
    And a user with id "2" has a role of "webcat user"
    And a user with id "3" has a role of "webcat user"
    And a user with id "4" has a role of "webcat user"
    And the following complaint entries exist:
      | id    | uri                 | domain          | entry_type | status  |
      | 1111  | abc.com             | abc.com         | URI/DOMAIN | NEW     |
      | 2222  | whatever.com        | whatever.com    | URI/DOMAIN | NEW     |
    And  I goto "/escalations/webcat/complaints"
    And  I wait for "3" seconds
    #Need to show User column with Second Reviewer data - hidden by default
    And I click "#webcat-index-table-show-columns-button"
    And I click "#view-user-col-cb"
    And I click "#view-data-sec-reviewer-cb"
    And I click row with id "1"
    And I click "#assignment-type-second-reviewer"
    And I click "#index_change_assign"
    And I wait for "1" seconds
    And I click "#index_target_assignee"
    And I click "#assignee_3"
    And I click "#button_reassign"
    And I wait for "1" seconds
    And I should see "Linda Belcher"

  @javascript
  Scenario: a manager can unassign an assignee from a complaint
    Given a user with role "webcat manager" exists and is logged in
    And the following users exist
      | id | cvs_username  | cec_username  | display_name   |
      | 2  | bob_belcher   | bob_belcher   | Bob Belcher    |
    And the following org_subsets exist:
      | id | name   |
      | 7  | webcat |
    And the following roles exist:
      | id | role        | org_subset_id |
      | 17 | webcat user |     7         |
    And a user with id "2" has a role of "webcat user"
    And the following complaint entries exist:
      | id    | uri                 | domain          | entry_type | status  |
      | 1111  | abc.com             | abc.com         | URI/DOMAIN | NEW     |
      | 2222  | whatever.com        | whatever.com    | URI/DOMAIN | NEW     |
    And  I goto "/escalations/webcat/complaints"
    And  I wait for "3" seconds
    #Need to show User column with Assignee data - hidden by default
    And I click "#webcat-index-table-show-columns-button"
    And I click "#view-user-col-cb"
    And I click "#view-data-assignee-cb"
    And I click row with id "1"
    And I click "#index_change_assign"
    And I wait for "1" seconds
    And I click "#button_reassign"
    And I wait for "1" seconds
    And I should see "Bob Belcher"
    And I click row with id "1"
    And I click ".remove-assignee-toolbar-button"
    And I should not see "Bob Belcher"

  @javascript
  Scenario: a manager can unassign a reviewer from a complaint
    Given a user with role "webcat manager" exists and is logged in
    And the following users exist
      | id | cvs_username  | cec_username  | display_name   |
      | 2  | bob_belcher   | bob_belcher   | Bob Belcher    |
      | 3  | linda_belcher | linda_belcher | Linda Belcher  |
      | 4  | tina_belcher  | tina_belcher  | Tina Belcher   |
    And the following org_subsets exist:
      | id | name   |
      | 7  | webcat |
    And the following roles exist:
      | id | role        | org_subset_id |
      | 17 | webcat user |     7         |
    And a user with id "2" has a role of "webcat user"
    And a user with id "3" has a role of "webcat user"
    And a user with id "4" has a role of "webcat user"
    And the following complaint entries exist:
      | id    | uri                 | domain          | entry_type | status  |
      | 1111  | abc.com             | abc.com         | URI/DOMAIN | NEW     |
      | 2222  | whatever.com        | whatever.com    | URI/DOMAIN | NEW     |
    And  I goto "/escalations/webcat/complaints"
    And  I wait for "3" seconds
    #Need to show User column with Reviewer data - hidden by default
    And I click "#webcat-index-table-show-columns-button"
    And I click "#view-user-col-cb"
    And I click "#view-data-reviewer-cb"
    And I click row with id "1"
    And I click "#assignment-type-reviewer"
    And I click "#index_change_assign"
    And I wait for "1" seconds
    And I click "#button_reassign"
    And I wait for "2" seconds
    And I should see "Bob Belcher"
    And I click ".remove-assignee-toolbar-button"
    And I should not see "Bob Belcher"

  @javascript
  Scenario: a manager can unassign a second reviewer from a complaint
    Given a user with role "webcat manager" exists and is logged in
    And the following users exist
      | id | cvs_username  | cec_username  | display_name   |
      | 2  | bob_belcher   | bob_belcher   | Bob Belcher    |
    And the following org_subsets exist:
      | id | name   |
      | 7  | webcat |
    And the following roles exist:
      | id | role        | org_subset_id |
      | 17 | webcat user |     7         |
    And a user with id "2" has a role of "webcat user"
    And the following complaint entries exist:
      | id    | uri                 | domain          | entry_type | status  |
      | 1111  | abc.com             | abc.com         | URI/DOMAIN | NEW     |
      | 2222  | whatever.com        | whatever.com    | URI/DOMAIN | NEW     |
    And  I goto "/escalations/webcat/complaints"
    And  I wait for "3" seconds
    #Need to show User column with Second Reviewer data - hidden by default
    And I click "#webcat-index-table-show-columns-button"
    And I click "#view-user-col-cb"
    And I click "#view-data-sec-reviewer-cb"
    And I click row with id "1"
    And I click "#assignment-type-second-reviewer"
    And I click "#index_change_assign"
    And I wait for "1" seconds
    And I click "#button_reassign"
    And I wait for "1" seconds
    And I should see "Bob Belcher"
    And I click ".remove-assignee-toolbar-button"
    And I should not see "Bob Belcher"

  @javascript
  Scenario: a manager cannot assign the same user as assignee and reviewer on a complaint
    Given a user with role "webcat manager" exists and is logged in
    And the following users exist
      | id | cvs_username  | cec_username  | display_name   |
      | 2  | bob_belcher   | bob_belcher   | Bob Belcher    |
    And the following org_subsets exist:
      | id | name   |
      | 7  | webcat |
    And the following roles exist:
      | id | role        | org_subset_id |
      | 17 | webcat user |     7         |
    And a user with id "2" has a role of "webcat user"
    And the following complaint entries exist:
      | id    | uri                 | domain          | entry_type | status  |
      | 1111  | abc.com             | abc.com         | URI/DOMAIN | NEW     |
      | 2222  | whatever.com        | whatever.com    | URI/DOMAIN | NEW     |
    And  I goto "/escalations/webcat/complaints"
    And  I wait for "3" seconds
    #Need to show User column - hidden by default
    And I click "#webcat-index-table-show-columns-button"
    And I click "#view-user-col-cb"
    And I click "#view-data-sec-reviewer-cb"
    And I click row with id "1"
    And I click "#index_change_assign"
    And I click "#button_reassign"
    And I wait for "1" seconds
    And I should see "Bob Belcher"
    #assign new assignee
    And I click "#index_change_assign"
    And I click "#button_reassign"
    And I wait for "2" seconds
    And I should see "The following entries could not be assigned: Complaint is already assigned to bob_belcher - 1"
    #assign new reviewer
    Then I click ".close"
    And I click "#assignment-type-reviewer"
    And I click "#index_change_assign"
    And I click "#button_reassign"
    And I wait for "2" seconds
    And I should see "The following entries could not be assigned: Complaint is already assigned to bob_belcher - 1"

  ## Note: The pending ticket does not work as expected at the moment
  @javascript
  Scenario: a manager cannot change assignee when complaint is PENDING or COMPLETE
    Given a user with role "webcat manager" exists and is logged in
    And the following users exist
      | id | cvs_username  | cec_username  | display_name   |
      | 2  | bob_belcher   | bob_belcher   | Bob Belcher    |
    And the following org_subsets exist:
      | id | name   |
      | 7  | webcat |
    And the following roles exist:
      | id | role        | org_subset_id |
      | 17 | webcat user |     7         |
    And a user with id "2" has a role of "webcat user"
    And the following complaint entries exist:
      | id    | uri                 | domain          | entry_type | status     |
      | 1111  | abc.com             | abc.com         | URI/DOMAIN | PENDING    |
      | 2222  | whatever.com        | whatever.com    | URI/DOMAIN | COMPLETED  |
    And  I goto "/escalations/webcat/complaints"
    And  I wait for "2" seconds
#    And I click row with id "1"
#    And I click "#index_change_assign"
#    And I click "#button_reassign"
#    And I wait for "1" seconds
#    And I should see "The following entries could not be assigned: Already completed - 1"
#    And I click row with id "1"
    And I click row with id "2"
    And I click "#index_change_assign"
    And I click "#button_reassign"
    And I wait for "2" seconds
    And I should see "The following entries could not be assigned: Already completed - 2"

  @javascript
  Scenario:  a non-manager can unassign a user from a complaint
    Given a user with role "webcat user" exists and is logged in
    And the following users exist
      | id | cvs_username | cec_username | display_name |
      | 3  | test_user    | test_user    | test_user    |
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type | status     | user_id | second_reviewer_id |
      | 1  | abc.com        | abc.com         | URI/DOMAIN | ASSIGNED   |    3    |               |
    And  I goto "/escalations/webcat/complaints"
    And the first Complaint Ticket is assigned to user id "3"
    #Need to show User column - hidden by default
    And I click "#webcat-index-table-show-columns-button"
    And I click "#view-user-col-cb"
    And I click "#view-data-assignee-cb"
    And  I click ".cat-index-main-row"
    Then I should see "ASSIGNED"
    And  I click ".remove-assignee-toolbar-button"
    Then I wait for "4" seconds
    And  I should not see "ASSIGNED"
    And  I should see "Vrt Incoming"
    And the first Complaint Ticket is not assigned to user id "3"

  @javascript
  Scenario:  a non-manager cannot unassign a reviewer from a complaint
    Given a user with role "webcat user" exists and is logged in
    And the following users exist
      | id | cvs_username  | cec_username | display_name |
      | 3  | test_user     | test_user    | test_user    |
      | 4  | test_user2    | test_user 2   | test_user2    |
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type | status     | user_id | reviewer_id  |
      | 1  | abc.com        | abc.com         | URI/DOMAIN | ASSIGNED   |    4    |     3        |
    And  I goto "/escalations/webcat/complaints"
    And I click ".cat-index-main-row"
    And I click "#assignment-type-reviewer"
    And I click ".return-ticket-toolbar-button"
    And I wait for "2" seconds
    And I should see "ERROR RETURNING ENTRIES"
    And I should see "The following entries could not be returned: Someone else is currently reviewing - 1"

  @javascript
  Scenario:  a non-manager cannot unassign a second reviewer from a complaint
    Given a user with role "webcat user" exists and is logged in
    And the following users exist
      | id | cvs_username  | cec_username  | display_name |
      | 3  | test_user     | test_user     | test_user    |
      | 4  | test_user2    | test_user2    | test_user2    |
      | 5  | test_user3    | test_user3    | test_user3    |
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type | status     | user_id | reviewer_id  |  reviewer_id  |
      | 1  | abc.com        | abc.com         | URI/DOMAIN | ASSIGNED   |    4    |     3        |       5       |
    And  I goto "/escalations/webcat/complaints"
    And I click ".cat-index-main-row"
    And I click "#assignment-type-second-reviewer"
    And I click ".return-ticket-toolbar-button"
    And I wait for "2" seconds
    And I should see "ERROR RETURNING ENTRIES"
    And I should see "The following entries could not be returned: Someone else is currently reviewing - 1"

  @javascript
  Scenario: a non-manager cannot assign a user other than themself to a complaint as assignee, reviewer or second reviewer
    Given a user with role "webcat user" exists within org subset "webcat" and is logged in
    And the following users exist
      | id | cvs_username  | cec_username  | display_name  |
      | 2  | test_user     | test_user     | test_user     |
      | 3  | test_user2    | test_user2    | test_user2    |
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type | status     | user_id | reviewer_id  |  reviewer_id  |
      | 1  | abc.com        | abc.com         | URI/DOMAIN | ASSIGNED   |    4    |     3        |       5       |
    And the following org_subsets exist:
      | id | name   |
      | 7  | webcat |
    And a user with id "2" has a role of "webcat user"
    And a user with id "3" has a role of "webcat user"
    And  I goto "/escalations/webcat/complaints"
    And I click row with id "1"
    And I click "#assignment-type-assignee"
    And button "webcat-remove-assignee-toolbar-button" should be enabled
    And button "index_change_assign" should be disabled
    And I click "#assignment-type-reviewer"
    And button "index_change_assign" should be disabled
    And I click "#assignment-type-second-reviewer"
    And button "index_change_assign" should be disabled


#  Scenario: a user cannot change the reviewer on a COMPLETED entry
#  Scenario: a user cannot change the second reviewer on a COMPLETED entry
