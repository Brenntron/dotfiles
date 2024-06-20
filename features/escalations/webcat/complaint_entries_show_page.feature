Feature: Complaint Entries Show Page
  Let users see a page with all relevant information for a Complaint Entry.

  Rule: Important Complaint Entries display the 'Important' icon for the analyst.

    @javascript
    Scenario:  A WebCat user navigates to a complaint entry that a reviewer declined.
      Given a user with role "webcat user" exists and is logged in
      And a complaint entry with trait "was_dismissed" exists
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see element ".highlight-was-dismissed"

    @javascript
    Scenario:  A WebCat user navigates to a complaint entry that was not declined by a reviewer.
      Given a user with role "webcat user" exists and is logged in
      And the following complaint entries exist:
        | id | uri     | domain  | entry_type | status |
        | 1  | abc.com | abc.com | URI/DOMAIN | NEW    |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should not see element ".highlight-was-dismissed"

  Rule: Tickets declined in review should display the 'Reviewed' icon for the analyst.

    @javascript
    Scenario:  A WebCat user navigates to a new important complaint entry.
      Given a user with role "webcat user" exists and is logged in
      And a complaint entry with trait "important" exists
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see element ".is-important"

    @javascript
    Scenario:  A WebCat user navigates to a complaint entry that is not important.
      Given a user with role "webcat user" exists and is logged in
      And the following complaint entries exist:
        | id | uri     | domain  | entry_type | status |
        | 1  | abc.com | abc.com | URI/DOMAIN | NEW    |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should not see element ".is-important"

  Rule: Users can take unassigned tickets

    @javascript
    Scenario: A WebCat user takes an unassigned ticket
      Given a user with role "webcat user" exists and is logged in
      And the following complaint entries exist:
        | id | uri     | domain  | entry_type | status |
        | 1  | abc.com | abc.com | URI/DOMAIN | NEW    |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see content "Unassigned" within "#complaint_assignee"
      When I click "#webcat_take_ticket_assignee"
      And I wait for "2" seconds
      Then I should see my display name in "#complaint_assignee"
      And I should not see content "Unassigned" within "#complaint_assignee"
      And I should not see button with id "webcat_take_ticket_assignee"
      And I should see button with id "webcat_return_ticket_assignee"

    @javascript
    Scenario: A WebCat user returns a ticket they are assigned
      Given a user with role "webcat user" exists and is logged in
      And the following complaint entries exist:
        | id | uri     | domain  | entry_type | status | user_id |
        | 1  | abc.com | abc.com | URI/DOMAIN | NEW    | 1       |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see my display name in "#complaint_assignee"
      When I click "#webcat_return_ticket_assignee"
      And I wait for "3" seconds
      Then I should not see my display name in "#complaint_assignee"
      And I should see button with id "webcat_take_ticket_assignee"
      And I should not see button with id "webcat_return_ticket_assignee"

    @javascript
    Scenario: A WebCat user tries to take a ticket with an assignee
      Given a user with role "webcat user" exists and is logged in
      And the following users exist
        | display_name |
        | User Two     |
      And the following complaint entries exist:
        | id | uri     | domain  | entry_type | status | user_id |
        | 1  | abc.com | abc.com | URI/DOMAIN | NEW    | 2       |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see content "User Two" within "#complaint_assignee"
      And I should not see button with id "webcat_take_ticket_assignee"

    @javascript
    Scenario: A WebCat user tries to return a Pending ticket they are assigned
      Given a user with role "webcat user" exists and is logged in
      And the following complaint entries exist:
        | id | uri     | domain  | entry_type | status  | user_id |
        | 1  | abc.com | abc.com | URI/DOMAIN | PENDING | 1       |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see my display name in "#complaint_assignee"
      And I should not see button with id "webcat_return_ticket_assignee"

  Rule: WebCat users can take the reviewer spot for a ticket without a reviewer

    @javascript
    Scenario: A WebCat user takes the reviewer slot for a ticket without a reviewer
      Given a user with role "webcat user" exists and is logged in
      And the following complaint entries exist:
        | id | uri     | domain  | entry_type | status |
        | 1  | abc.com | abc.com | URI/DOMAIN | NEW    |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see content "Unassigned" within "#complaint_reviewer"
      When I click "#webcat_take_ticket_reviewer"
      Then I should see my display name in "#complaint_reviewer"
      And I should not see content "Unassigned" within "#complaint_reviewer"
      And I should not see button with id "webcat_take_ticket_reviewer"
      And I should see button with id "webcat_return_ticket_reviewer"

    @javascript
    Scenario: A WebCat user returns a ticket they are reviewing as the reviewer
      Given a user with role "webcat user" exists and is logged in
      And the following users exist
        | display_name |
        | User Two     |
      And the following complaint entries exist:
        | id | uri     | domain  | entry_type | status | user_id | reviewer_id |
        | 1  | abc.com | abc.com | URI/DOMAIN | NEW    | 2       | 1           |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see my display name in "#complaint_reviewer"
      When I click "#webcat_return_ticket_reviewer"
      Then I should not see my display name in "#complaint_reviewer"
      And I should not see button with id "webcat_take_ticket_assignee"
      And I should not see button with id "webcat_return_ticket_assignee"

    @javascript
    Scenario: A WebCat user takes the second reviewer slot for a ticket without a second reviewer
      Given a user with role "webcat user" exists and is logged in
      And the following complaint entries exist:
        | id | uri     | domain  | entry_type | status |
        | 1  | abc.com | abc.com | URI/DOMAIN | NEW    |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see content "Unassigned" within "#complaint_second_reviewer"
      When I click "#webcat_take_ticket_second_reviewer"
      Then I should see my display name in "#complaint_second_reviewer"
      And I should not see content "No 2nd Reviewer" within "#complaint_second_reviewer"
      And I should see button with id "webcat_return_ticket_second_reviewer"
      And I should not see button with id "webcat_take_ticket_second_reviewer"

    @javascript
    Scenario: A WebCat user returns a ticket they are reviewing as the second reviewer
      Given a user with role "webcat user" exists and is logged in
      And the following users exist
        | display_name |
        | User Two     |
      And the following complaint entries exist:
        | id | uri     | domain  | entry_type | status | user_id | second_reviewer_id |
        | 1  | abc.com | abc.com | URI/DOMAIN | NEW    | 2       | 1                  |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see my display name in "#complaint_second_reviewer"
      When I click "#webcat_return_ticket_second_reviewer"
      Then I should not see my display name in "#complaint_second_reviewer"
      And I should see content "No 2nd Reviewer" within "#complaint_second_reviewer"

  Rule: WebCat users cannot be reviewers for tickets they are assigned
    @javascript
    Scenario: A WebCat user tries to take a review spot for a ticket they are assigned.
      Given a user with role "webcat user" exists and is logged in
      And the following complaint entries exist:
        | id | uri     | domain  | entry_type | status | user_id |
        | 1  | abc.com | abc.com | URI/DOMAIN | NEW    | 1       |
      When I goto "/escalations/webcat/complaint_entries/1"
      And I click "#webcat_take_ticket_reviewer"
      Then I should see content "The Assignee cannot also be a Reviewer." within ".error-msg"
      And I should not see my display name in "#complaint_reviewer"

  Rule: WebCat users cannot be other reviewer for tickets they are already reviewing.

    @javascript
    Scenario: A WebCat user tries to take the second reviewer spot for a ticket where they are the reviewer
      Given a user with role "webcat user" exists and is logged in
      And the following users exist
        | display_name   |
        | User Two       |
      And the following complaint entries exist:
        | id | uri     | domain  | entry_type | status | user_id | reviewer_id |
        | 1  | abc.com | abc.com | URI/DOMAIN | NEW    | 2       | 1           |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see my display name in "#complaint_reviewer"
      When I click "#webcat_take_ticket_second_reviewer"
      Then I should see content "The Reviewer cannot also be the Second Reviewer." within ".error-msg"
      Then I should not see my display name in "#complaint_second_reviewer"

    @javascript
    Scenario: A WebCat user tries to take the reviewer spot for a ticket when they are the second reviewer
      Given a user with role "webcat user" exists and is logged in
      And the following users exist
        | display_name   |
        | User Two       |
      And the following complaint entries exist:
        | id | uri     | domain  | entry_type | status | user_id | second_reviewer_id |
        | 1  | abc.com | abc.com | URI/DOMAIN | NEW    | 2       | 1                  |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see my display name in "#complaint_second_reviewer"
      When I click "#webcat_take_ticket_reviewer"
      Then I should see content "The Second Reviewer cannot also be the Reviewer." within ".error-msg"

  Rule: Only a webcat manager can assign other webcat users to a ticket

    @javascript
    Scenario: A WebCat manager assigns a ticket without an assignee to a WebCat user.
      Given a user with role "webcat manager" exists and is logged in
      And the following webcat users exist
        | display_name |
        | User Two     |
      And the following complaint entries exist:
        | id | uri     | domain  | entry_type | status |
        | 1  | abc.com | abc.com | URI/DOMAIN | NEW    |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see content "Unassigned" within "#complaint_assignee"
      When I click "#show_change_assignee"
      Then "User Two" should be in the "change_target_assignee" dropdown list
      And I select "2" from the "change_target_assignee" dropdown list
      And I click "#button_reassign"
      Then I should see content "User Two" within "#complaint_assignee"

    @javascript
    Scenario: A WebCat manager reassigns a ticket with an assignee to a WebCat user.
      Given a user with role "webcat manager" exists and is logged in
      And the following webcat users exist
        | display_name |
        | User Two     |
        | User Three   |
      And the following complaint entries exist:
        | id | uri     | domain  | entry_type | status | user_id |
        | 1  | abc.com | abc.com | URI/DOMAIN | NEW    | 2       |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see content "User Two" within "#complaint_assignee"
      When I click "#show_change_assignee"
      Then "User Three" should be in the "change_target_assignee" dropdown list
      And I select "3" from the "change_target_assignee" dropdown list
      And I click "#button_reassign"
      Then I should see content "User Three" within "#complaint_assignee"

    @javascript
    Scenario: A WebCat manager assigns a reviewer for a ticket without a reviewer.
      Given a user with role "webcat manager" exists and is logged in
      And the following webcat users exist
        | display_name |
        | User Two     |
      And the following complaint entries exist:
        | id | uri     | domain  | entry_type | status |
        | 1  | abc.com | abc.com | URI/DOMAIN | NEW    |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see content "No Reviewer" within "#complaint_reviewer"
      When I click "#show_change_reviewer"
      Then "User Two" should be in the "change_target_reviewer" dropdown list
      And I select "2" from the "change_target_reviewer" dropdown list
      And I click "#button_reassign"
      Then I should see content "User Two" within "#complaint_reviewer"

    @javascript
    Scenario: A WebCat manager reassigns the reviewer for a ticket with an reviewer.
      Given a user with role "webcat manager" exists and is logged in
      And the following webcat users exist
        | display_name |
        | User Two     |
        | User Three   |
      And the following complaint entries exist:
        | id | uri     | domain  | entry_type | status | reviewer_id |
        | 1  | abc.com | abc.com | URI/DOMAIN | NEW    | 2       |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see content "User Two" within "#complaint_reviewer"
      When I click "#show_change_reviewer"
      Then "User Three" should be in the "change_target_reviewer" dropdown list
      And I select "3" from the "change_target_reviewer" dropdown list
      And I click "#button_reassign"
      Then I should see content "User Three" within "#complaint_reviewer"

    @javascript
    Scenario: A WebCat manager assigns a second reviewer for a ticket without a second reviewer.
      Given a user with role "webcat manager" exists and is logged in
      And the following webcat users exist
        | display_name |
        | User Two     |
      And the following complaint entries exist:
        | id | uri     | domain  | entry_type | status |
        | 1  | abc.com | abc.com | URI/DOMAIN | NEW    |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see content "No 2nd Reviewer" within "#complaint_second_reviewer"
      When I click "#show_change_second_reviewer"
      Then "User Two" should be in the "change_target_second_reviewer" dropdown list
      And I select "2" from the "change_target_second_reviewer" dropdown list
      And I click "#button_reassign"
      Then I should see content "User Two" within "#complaint_second_reviewer"

    @javascript
    Scenario: A WebCat manager reassigns the second reviewer for a ticket with an second_reviewer.
      Given a user with role "webcat manager" exists and is logged in
      And the following webcat users exist
        | display_name |
        | User Two     |
        | User Three   |
      And the following complaint entries exist:
        | id | uri     | domain  | entry_type | status | second_reviewer_id |
        | 1  | abc.com | abc.com | URI/DOMAIN | NEW    | 2                  |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see content "User Two" within "#complaint_second_reviewer"
      When I click "#show_change_second_reviewer"
      Then "User Three" should be in the "change_target_second_reviewer" dropdown list
      And I select "3" from the "change_target_second_reviewer" dropdown list
      And I click "#button_reassign"
      Then I should see content "User Three" within "#complaint_second_reviewer"

    @javascript
    Scenario: A WebCat manager can't assign a ticket to a non-WebCat user.
      Given a user with role "webcat manager" exists and is logged in
      And the following users exist
        | display_name |
        | User Two     |
      And the following complaint entries exist:
        | id | uri     | domain  | entry_type | status | user_id |
        | 1  | abc.com | abc.com | URI/DOMAIN | NEW    | 2       |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see content "Unassigned" within "#complaint_assignee"
      And I should see content "No Reviewer" within "#complaint_reviewer"
      And I should see content "No 2nd Reviewer" within "#complaint_second_reviewer"
      When I click "#show_change_assignee"
      Then "User Two" should not be in the "change_target_assignee" dropdown list
      When I click "#show_change_assignee"
      When I click "#show_change_reviewer"
      Then "User Two" should not be in the "change_target_reviewer" dropdown list
      When I click "#show_change_reviewer"
      When I click "#show_change_second_reviewer"
      Then "User Two" should not be in the "change_target_second_reviewer" dropdown list
