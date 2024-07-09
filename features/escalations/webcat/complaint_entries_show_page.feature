Feature: Complaint Entries Show Page
  Let users see a page with all relevant information for a Complaint Entry.

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

  @javascript
  Scenario:  A WebCat user navigates to a complaint entry that a reviewer declined.
    Given a user with role "webcat user" exists and is logged in
    And a complaint entry with trait "was_dismissed" exists
    When I goto "/escalations/webcat/complaint_entries/1"
    Then I should see element ".was-reviewed"

  @javascript
  Scenario:  A WebCat user navigates to a complaint entry that was not declined by a reviewer.
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri     | domain  | entry_type | status |
      | 1  | abc.com | abc.com | URI/DOMAIN | NEW    |
    When I goto "/escalations/webcat/complaint_entries/1"
    Then I should not see element ".was-reviewed"

  @javascript
  Scenario: A user should see suggested categories
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri     | domain  | entry_type | status | suggested_disposition   |
      | 1  | abc.com | abc.com | URI/DOMAIN | NEW    | Animals and Pets, Games |
      | 2  | def.com | def.com | URI/DOMAIN | NEW    |                         |
    When I goto "/escalations/webcat/complaint_entries/1"
    Then I should see an element "#ce_suggested_categories" with text "Animals and Pets, Games"
    When I goto "/escalations/webcat/complaint_entries/2"
    Then I should see an element "#ce_suggested_categories" with text "No suggested categories available."

  @javascript
  Scenario: URI buttons should be disabled for IP entries.
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri           | domain  | subdomain | path | ip_address | entry_type | status |
      | 1  |               |         |           |      | 1.1.1.1    | IP         | NEW    |
    When I goto "/escalations/webcat/complaint_entries/1"
    Then button with id "ce_ip_uri_domain" should be disabled
    And button with id "ce_ip_uri_subdomain" should be disabled
    And button with id "ce_ip_uri_original" should be disabled
    When I type content "5" within input with id "ce_ip_uri_input"
    And I hit enter within "#ce_ip_uri_input"
    Then button with id "ce_ip_uri_domain" should be disabled
    And button with id "ce_ip_uri_subdomain" should be disabled
    And button with id "ce_ip_uri_original" should be disabled

  @javascript
  Scenario: The domain and subdomain uri buttons should enable for Complaint Entries with a subdomain and a path.
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri                  | domain  | subdomain | path | entry_type | status | ip_address |
      | 1  | alphabet.abc.com/zyx | abc.com | alphabet  | /zyx | URI/DOMAIN | NEW    |            |
    When I goto "/escalations/webcat/complaint_entries/1"
    Then Input with id "ce_ip_uri_input" should have value "alphabet.abc.com/zyx"
    Then button with id "ce_ip_uri_domain" should be enabled
    And button with id "ce_ip_uri_subdomain" should be enabled
    And button with id "ce_ip_uri_original" should be disabled
    When I type content "new" within input with id "ce_ip_uri_input"
    And I hit enter within "#ce_ip_uri_input"
    And I wait for "2" seconds
    Then button with id "ce_ip_uri_domain" should be enabled
    And button with id "ce_ip_uri_subdomain" should be enabled
    And button with id "ce_ip_uri_original" should be enabled
    When I click "#ce_ip_uri_subdomain"
    Then Input with id "ce_ip_uri_input" should have value "alphabet.abc.com"
    And button with id "ce_ip_uri_subdomain" should be disabled
    When I click "#ce_ip_uri_domain"
    Then Input with id "ce_ip_uri_input" should have value "abc.com"
    And button with id "ce_ip_uri_domain" should be disabled
    And button with id "ce_ip_uri_subdomain" should be enabled
    When I click "#ce_ip_uri_original"
    Then Input with id "ce_ip_uri_input" should have value "alpha.abc.com"
    And button with id "ce_ip_uri_original" should be disabled
    Then button with id "ce_ip_uri_domain" should be enabled
    And button with id "ce_ip_uri_subdomain" should be enabled

  @javascript
  Scenario: The domain uri button should enable for Complaint Entries with a subdomain but no path.
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri           | domain  | subdomain | path | ip_address | entry_type | status |
      | 1  | alpha.def.com | def.com | alpha     |      |            | URI/DOMAIN | NEW    |
    When I goto "/escalations/webcat/complaint_entries/1"
    Then Input with id "ce_ip_uri_input" should have value "alpha.abc.com"
    Then button with id "ce_ip_uri_domain" should be enabled
    And button with id "ce_ip_uri_subdomain" should be disabled
    And button with id "ce_ip_uri_original" should be disabled
    When I type content "new" within input with id "ce_ip_uri_input"
    And I hit enter within "#ce_ip_uri_input"
    Then button with id "ce_ip_uri_domain" should be enabled
    And button with id "ce_ip_uri_subdomain" should be enabled
    And button with id "ce_ip_uri_original" should be enabled
    When I click "#ce_ip_uri_subdomain"
    Then Input with id "ce_ip_uri_input" should have value "alphabet.abc.com"
    And button with id "ce_ip_uri_subdomain" should be disabled
    Then button with id "ce_ip_uri_domain" should be enabled
    And button with id "ce_ip_uri_original" should be disabled
    When I click "ce_ip_uri_domain"
    Then Input with id "ce_ip_uri_input" should have value "abc.com"
    And button with id "ce_ip_uri_domain" should be disabled
    And button with id "ce_ip_uri_subdomain" should be enabled
    When I click "#ce_ip_uri_original"
    Then Input with id "ce_ip_uri_input" should have value "alpha.abc.com"
    And button with id "ce_ip_uri_original" should be disabled
    Then button with id "ce_ip_uri_domain" should be enabled
    And button with id "ce_ip_uri_subdomain" should be disabled

  @javascript
  Scenario: All uri buttons should be disabled for uri/domain Complaint Entries without a path and subdomain.
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri           | domain  | subdomain | path | ip_address | entry_type | status |
      | 1  | ghi.com       | ghi.com |           |      |            | URI/DOMAIN | NEW    |
    When I goto "/escalations/webcat/complaint_entries/1"
    Then button with id "ce_ip_uri_domain" should be disabled
    And button with id "ce_ip_uri_subdomain" should be disabled
    And button with id "ce_ip_uri_original" should be disabled
    When I type content "change" within input with id "ce_ip_uri_input"
    And I hit enter within "#ce_ip_uri_input"
    Then button with id "ce_ip_uri_domain" should be enabled
    And button with id "ce_ip_uri_subdomain" should be disabled
    And button with id "ce_ip_uri_original" should be enabled

  @javascript
  Scenario: A WebCat user can reopen COMPLETED tickets
    Given a user with role "webcat user" exists and is logged in
    And the following complaints exist:
      | id | description        |  submitter_type | ticket_source      | status    |
      | 1  | weather            |  CUSTOMER       | talos-intelligence | COMPLETED |
    And the following complaint entries exist:
      | id | uri           | domain  | ip_address | entry_type | status    | resolution | complaint_id | resolution_comment  |
      | 1  | ghi.com       | ghi.com |            | URI/DOMAIN | COMPLETED | FIXED      | 1            | 'Resolution Comment'|
    When I goto "/escalations/webcat/complaint_entries/1"
    And I click "#ce_reopen_button"
    And I wait for "7" seconds
    Then I should see an element "#complaint_entry_status" with text "REOPENED"

  @javascript
  Scenario: A WebCat user cannot reopen duplicates
    Given a user with role "webcat user" exists and is logged in
    And the following complaints exist:
      | id | description        |  submitter_type | ticket_source      | status    |
      | 1  | weather            |  CUSTOMER       | talos-intelligence | COMPLETED |
      | 2  | not weather        |  CUSTOMER       | talos-intelligence | COMPLETED |
    And the following complaint entries exist:
      | id | uri           | domain  | ip_address | entry_type | status       | resolution | complaint_id | resolution_comment   |
      | 1  | ghi.com       | ghi.com |            | URI/DOMAIN | COMPLETED    | DUPLICATE  | 1            | 'Resolution Comment' |
      | 2  | abc.com       | abc.com |            | URI/DOMAIN | WC-DUPLICATE |            | 2            | 'Resolution Comment' |
    When I goto "/escalations/webcat/complaint_entries/1"
    Then I should not see element "#ce_reopen_button"
    When I goto "/escalations/webcat/complaint_entries/2"
    Then I should not see element "#ce_reopen_button"

  # TODO - this does not work in testing env yet - the pop up does not prevent refresh, could be a ff setting
  # since firefox disabled pop ups by default. We might need tweaks to testing browser
  # @javascript
  # Scenario: a user sees a pop-up window if they make changes to an entry but do not submit
  #   Given a user with role "webcat user" exists and is logged in
  #   And the following complaint entries exist:
  #     | id | uri                         | domain                | ip_address | entry_type | status |
  #     | 1  | dungeonsanddoggos.com       | dungeonsanddoggos.com |            | URI/DOMAIN | NEW    |
  #   When I goto "/escalations/webcat/complaint_entries/1"
  #   And I wait for "2" seconds
  #   And I fill in selectized of element "#ce_categories_select" with "107"
  #   And I click "#complaints"
  #   And I wait for "2" seconds
  #   Then I switch to the alert
  #   And take a screenshot
  #   And I should see alert

  @javascript
  Scenario: a WebCat user sees the whois information for a domain
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri                         | domain                | ip_address | entry_type | status |
      | 1  | dungeonsanddoggos.com       | dungeonsanddoggos.com |            | URI/DOMAIN | NEW    |
    And I can receive a whois lookup request
    When I goto "/escalations/webcat/complaint_entries/1"
    And I wait for "2" seconds
    Then I should see content "DUNGEONSANDDOGGOS.COM" within "#whois_data_container"

  Rule: Users can take unassigned tickets

    @javascript
    Scenario: A WebCat user takes an unassigned ticket
      Given a user with role "webcat user" exists and is logged in
      And the following complaint entries exist:
        | id | uri     | domain  | entry_type | status |
        | 1  | abc.com | abc.com | URI/DOMAIN | NEW    |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see an element "#complaint_assignee" with text "Unassigned"
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
      Then I should see an element "#complaint_assignee" with text "User Two"
      And I should not see button with id "webcat_take_ticket_assignee"

    @javascript
    Scenario: A WebCat user tries to return a Pending ticket they are assigned
      Given a user with role "webcat user" exists and is logged in
      And the following complaint entries exist:
        | id | uri     | domain  | entry_type | status  | user_id | is_important |
        | 1  | abc.com | abc.com | URI/DOMAIN | PENDING | 1       | true         |
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
      Then I should see an element "#complaint_reviewer" with text "No Reviewer"
      When I click "#webcat_take_ticket_reviewer"
      Then I should see my display name in "#complaint_reviewer"
      And I should not see content "No Reviewer" within "#complaint_reviewer"
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
      Then I should see an element "#complaint_second_reviewer" with text "No 2nd Reviewer"
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
      And I wait for "2" seconds
      Then I should not see my display name in "#complaint_second_reviewer"
      And I should see an element "#complaint_second_reviewer" with text "No 2nd Reviewer"

  Rule: WebCat users cannot be reviewers for tickets they are assigned
    @javascript
    Scenario: A WebCat user tries to take a review spot for a ticket they are assigned.
      Given a user with role "webcat user" exists and is logged in
      And the following complaint entries exist:
        | id | uri     | domain  | entry_type | status | user_id |
        | 1  | abc.com | abc.com | URI/DOMAIN | NEW    | 1       |
      When I goto "/escalations/webcat/complaint_entries/1"
      And I click "#webcat_take_ticket_reviewer"
      Then I should see an element ".error-msg" with text "The Assignee cannot also be a Reviewer."
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
      Then I should see an element ".error-msg" with text "The Second Reviewer cannot also be the Reviewer."
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
      Then I should see an element ".error-msg" with text "The Reviewer cannot also be the Second Reviewer."

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
      Then I should see an element "#complaint_assignee" with text "Unassigned"
      When I click "#show_change_assignee"
      Then "User Two" should be in the "change_target_assignee" dropdown list
      And I select "2" from the "change_target_assignee" dropdown list
      And I click "#button_reassign"
      Then I should see an element "#complaint_assignee" with text "User Two"

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
      Then I should see an element "#complaint_assignee" with text "User Two"
      When I click "#show_change_assignee"
      Then "User Three" should be in the "change_target_assignee" dropdown list
      And I select "3" from the "change_target_assignee" dropdown list
      And I click "#button_reassign"
      Then I should see an element "#complaint_assignee" with text "User Three"

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
      Then I should see an element "#complaint_reviewer" with text "No Reviewer"
      When I click "#show_change_reviewer"
      Then "User Two" should be in the "change_target_reviewer" dropdown list
      And I select "2" from the "change_target_reviewer" dropdown list
      And I click "#button_reassign"
      Then I should see an element "#complaint_reviewer" with text "User Two"

    @javascript
    Scenario: A WebCat manager reassigns the reviewer for a ticket with an reviewer.
      Given a user with role "webcat manager" exists and is logged in
      And the following webcat users exist
        | display_name |
        | User Two     |
        | User Three   |
      And the following complaint entries exist:
        | id | uri     | domain  | entry_type | status | reviewer_id |
        | 1  | abc.com | abc.com | URI/DOMAIN | NEW    | 2           |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see an element "#complaint_reviewer" with text "User Two"
      When I click "#show_change_reviewer"
      Then "User Three" should be in the "change_target_reviewer" dropdown list
      And I select "3" from the "change_target_reviewer" dropdown list
      And I click "#button_reassign"
      Then I should see an element "#complaint_reviewer" with text "User Three"

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
      Then I should see an element "#complaint_second_reviewer" with text "No 2nd Reviewer"
      When I click "#show_change_second_reviewer"
      Then "User Two" should be in the "change_target_second_reviewer" dropdown list
      And I select "2" from the "change_target_second_reviewer" dropdown list
      And I click "#button_reassign"
      Then I should see an element "#complaint_second_reviewer" with text "User Two"

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
      Then I should see an element "#complaint_second_reviewer" with text "User Two"
      When I click "#show_change_second_reviewer"
      Then "User Three" should be in the "change_target_second_reviewer" dropdown list
      And I select "3" from the "change_target_second_reviewer" dropdown list
      And I click "#button_reassign"
      Then I should see an element "#complaint_second_reviewer" with text "User Three"

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
      Then I should see an element "#complaint_assignee" with text "User Two"
      And I should see an element "#complaint_reviewer" with text "No Reviewer"
      And I should see an element "#complaint_second_reviewer" with text "No 2nd Reviewer"
      When I click "#show_change_assignee"
      Then "User Two" should not be in the "change_target_assignee" dropdown list
      When I click "#show_change_assignee"
      When I click "#show_change_reviewer"
      Then "User Two" should not be in the "change_target_reviewer" dropdown list
      When I click "#show_change_reviewer"
      When I click "#show_change_second_reviewer"
      Then "User Two" should not be in the "change_target_second_reviewer" dropdown list

  Rule: Analysts cannot open the url for untrusted Complaint Entries

    @javascript
    Scenario: Should not open Complaint Entry url in a new tab if the WBRS Score is -6 or lower.
      Given a user with role "webcat user" exists and is logged in
      And the following complaint entries exist:
      | id | uri     | domain  | entry_type | status | user_id | wbrs_score | viewable | ip_address |
      | 1  | abc.com | abc.com | URI/DOMAIN | NEW    | 1       | -6         | true     |            |
      When I goto "/escalations/webcat/complaint_entries/1"
      And I click ".open-all"
      And I wait for "2" seconds
      Then I should see an element ".alert-danger" with text "abc.com could not open due to low WBRS Scores."

    @javascript
    Scenario: Should open Complaint Entry url in a new tab if the WBRS Score is lower than -6.
      Given a user with role "webcat user" exists and is logged in
      And the following complaint entries exist:
      | id | uri     | domain  | entry_type | status | user_id | wbrs_score | viewable |
      | 1  | abc.com | abc.com | URI/DOMAIN | NEW    | 1       | 6          | true     |
      When I goto "/escalations/webcat/complaint_entries/1"
      And I click ".open-all"
      And I wait for "2" seconds
      Then a new window should be opened

    @javascript
    Scenario: Should not open Complaint Entry url in a new tab that are not viewable.
      Given a user with role "webcat user" exists and is logged in
      And the following complaint entries exist:
      | id | uri     | domain  | entry_type | status | user_id | wbrs_score | viewable |
      | 1  | abc.com | abc.com | URI/DOMAIN | NEW    | 1       | 6          | false     |
      When I goto "/escalations/webcat/complaint_entries/1"
      And I click ".open-all"
      And I wait for "2" seconds
      Then I should see an element ".alert-danger" with text "Complaint Address is not viewable."

  Rule: Complaint Entries should only submit as Fixed when the requisite changes are present.

    @javascript
    Scenario: A WebCat user submits a complaint entry as Fixed with all required fields filled out and has a resolution template.
      Given a user with role "webcat user" exists and is logged in
      And the following complaint entries exist:
      | id | uri     | domain  | entry_type | status | user_id |
      | 1  | abc.com | abc.com | URI/DOMAIN | NEW    | 1       |
      And the following webcat resolution message templates exist:
      | name     | body                              | resolution_type | description |
      | Fixed 01 | This is the first Fixed comment   | Fixed           | first       |
      | Fixed 02 | This is the second Fixed comment  | Fixed           | second      |
      When I goto "/escalations/webcat/complaint_entries/1"
      And I wait for "2" seconds
      Then I should see the radio with id "res-fixed-radio" checked
      And I fill in selectized of element "#ce_categories_select" with "107"
      And I wait for "2" seconds
      Then button with id "ce_submit_button" should be enabled
      When I select "Fixed 02" from "entry-email-response-to-customers-select_1"
      When I click "#ce_submit_button"
      And I wait for "7" seconds
      Then I should see an element "#complaint_entry_status" with text "COMPLETED"

    @javascript
    Scenario: A WebCat user submits a complaint entry as Fixed with all required fields filled out without a resolution template.
      Given a user with role "webcat user" exists and is logged in
      And the following complaint entries exist:
      | id | uri     | domain  | entry_type | status | user_id |
      | 1  | abc.com | abc.com | URI/DOMAIN | NEW    | 1       |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see the radio with id "res-fixed-radio" checked
      And button with id "ce_submit_button" should be disabled
      When I wait for "2" seconds
      And I fill in selectized of element "#ce_categories_select" with "107"
      Then button with id "ce_submit_button" should be enabled
      When I click "#ce_submit_button"
      And I wait for "10" seconds
      Then I should see an element ".error-msg" with text "MUST HAVE A MESSAGE TO THE CUSTOMER"

    @javascript
    Scenario: The submit button should disable when the requisite changes for submission are removed.
      Given a user with role "webcat user" exists and is logged in
      And the following complaint entries exist:
      | id | uri     | domain  | entry_type | status | user_id |
      | 1  | abc.com | abc.com | URI/DOMAIN | NEW    | 1       |
      When I goto "/escalations/webcat/complaint_entries/1"
      And I wait for "2" seconds
      Then I should see the radio with id "res-fixed-radio" checked
      And button with id "ce_submit_button" should be disabled
      And I fill in selectized of element "#ce_categories_select" with "107"
      And I wait for "2" seconds
      Then button with id "ce_submit_button" should be enabled
      When I remove item "107" from the selectized of element "#ce_categories_select"
      And I wait for "2" seconds
      Then button with id "ce_submit_button" should be disabled

  Rule: Submit button should only enable for unchanged when there are no present changes

    @javascript
    Scenario:  A user submits an unchanged Complaint Entry with no changes
      Given a user with role "webcat user" exists and is logged in
      And the following complaint entries exist:
      | id | uri     | domain  | entry_type | status | user_id |
      | 1  | abc.com | abc.com | URI/DOMAIN | NEW    | 1       |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see the radio with id "res-fixed-radio" checked
      And button with id "ce_submit_button" should be disabled
      When I click "#res-unchanged-radio"
      And I wait for "2" seconds
      Then button with id "ce_submit_button" should be enabled
      When I click "#ce_submit_button"
      And I wait for "10" seconds
      Then I should see an element "#complaint_entry_status" with text "COMPLETED"

    @javascript
    Scenario:  A user attempts to submit an unchanged Complaint Entry with changes present
      Given a user with role "webcat user" exists and is logged in
      And the following complaint entries exist:
      | id | uri     | domain  | entry_type | status | user_id |
      | 1  | abc.com | abc.com | URI/DOMAIN | NEW    | 1       |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see the radio with id "res-fixed-radio" checked
      And button with id "ce_submit_button" should be disabled
      When I click "#res-unchanged-radio"
      And I fill in selectized of element "#ce_categories_select" with "107"
      And I wait for "2" seconds
      Then button with id "ce_submit_button" should be disabled

  Rule: Complaint Entries must have a response to customer.
   @javascript
    Scenario: A WebCat User submits a complaint entry as fixed without a response to the customer
      Given a user with role "webcat user" exists and is logged in
      And the following complaint entries exist:
      | id | uri     | domain  | entry_type | status | user_id |
      | 1  | abc.com | abc.com | URI/DOMAIN | NEW    | 1       |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see the radio with id "res-fixed-radio" checked
      And I wait for "2" seconds
      And button with id "ce_submit_button" should be disabled
      When I fill in selectized of element "#ce_categories_select" with "107"
      And I click "#ce_submit_button"
      Then I should see content "MUST HAVE A MESSAGE TO THE CUSTOMER" within ".error-msg"

  Rule: Submit button should only enable for invalid when there are no present changes

    @javascript
    Scenario:  A user submits an invalid Complaint Entry with no changes
      Given a user with role "webcat user" exists and is logged in
      And the following complaint entries exist:
      | id | uri     | domain  | entry_type | status | user_id |
      | 1  | abc.com | abc.com | URI/DOMAIN | NEW    | 1       |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see the radio with id "res-fixed-radio" checked
      And button with id "ce_submit_button" should be disabled
      When I click "#res-invalid-radio"
      And I wait for "2" seconds
      Then button with id "ce_submit_button" should be enabled
      When I click "#ce_submit_button"
      And I wait for "10" seconds
      Then I should see content "COMPLETED" within "#complaint_entry_status"

    @javascript
    Scenario:  A user attempts to submit an invalid Complaint Entry with changes present
      Given a user with role "webcat user" exists and is logged in
      And the following complaint entries exist:
      | id | uri     | domain  | entry_type | status | user_id |
      | 1  | abc.com | abc.com | URI/DOMAIN | NEW    | 1       |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see the radio with id "res-fixed-radio" checked
      And button with id "ce_submit_button" should be disabled
      When I click "#res-invalid-radio"
      And I fill in selectized of element "#ce_categories_select" with "107"
      And I wait for "2" seconds
      Then button with id "ce_submit_button" should be disabled

  Rule: Important Complaint Entries should go to PENDING after submission

    @javascript
    Scenario: The status of a complaint entry should be PENDING after submission as FIXED
      Given a user with role "webcat user" exists and is logged in
      And the following complaint entries exist:
      | id | uri     | domain  | entry_type | status | user_id |
      | 1  | abc.com | abc.com | URI/DOMAIN | NEW    | 1       |
      When I goto "/escalations/webcat/complaint_entries/1"
      And I wait for "2" seconds
      And I fill in selectized of element "#ce_categories_select" with "107"
      And I type content "Customer Response" within input with id "entry-email-response-to-customers_1"
      And I wait for "2" seconds
      And I click "#ce_submit_button"
      And I wait for "7" seconds
      Then I should see content "PENDING" within "#complaint_entry_status"

  Rule: Analysts can review pending tickets

    @javascript
    Scenario: An analyst should commit a pending ticket as the Reviewer
      Given a user with role "webcat user" exists and is logged in
      And the following users exist
        | display_name   |
        | User Two       |
      And the following complaint entries exist:
        | id | uri     | entry_type | status  | user_id | reviewer_id | resolution | is_important |
        | 1  | abc.com | URI/DOMAIN | PENDING | 2       | 1           | FIXED      | true         |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see the radio with id "res-fixed-radio" checked
      And button with id "ce_submit_button" should be disabled
      When I click "#review_commit_radio"
      Then button with id "ce_submit_button" should be enabled
      When I click "#ce_submit_button"
      And I wait for "10" seconds
      Then I should see content "COMPLETED" within "#complaint_entry_status"

    @javascript
    Scenario: An analyst should decline a pending ticket as the Reviewer
      Given a user with role "webcat user" exists and is logged in
      And the following users exist
        | display_name   |
        | User Two       |
      And the following complaint entries exist:
        | id | uri     | entry_type | status  | user_id | reviewer_id | resolution | is_important |
        | 1  | abc.com | URI/DOMAIN | PENDING | 2       | 1           | FIXED      | true         |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see the radio with id "res-fixed-radio" checked
      And button with id "ce_submit_button" should be disabled
      When I click "#review_decline_radio"
      Then button with id "ce_submit_button" should be enabled
      When I click "#ce_submit_button"
      And I wait for "10" seconds
      Then I should see content "ASSIGNED" within "#complaint_entry_status"

    @javascript
    Scenario: An analyst should commit a pending ticket as the Second Reviewer
      Given a user with role "webcat user" exists and is logged in
      And the following users exist
        | display_name   |
        | User Two       |
      And the following complaint entries exist:
        | id | uri     | entry_type | status  | user_id | second_reviewer_id | resolution | is_important |
        | 1  | abc.com | URI/DOMAIN | PENDING | 2       | 1                  | FIXED      | true         |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see the radio with id "res-fixed-radio" checked
      And button with id "ce_submit_button" should be disabled
      When I click "#review_commit_radio"
      Then button with id "ce_submit_button" should be enabled
      When I click "#ce_submit_button"
      And I wait for "10" seconds
      Then I should see content "COMPLETED" within "#complaint_entry_status"

    @javascript
    Scenario: An analyst should decline a pending ticket as the Second Reviewer
      Given a user with role "webcat user" exists and is logged in
      And the following users exist
        | display_name   |
        | User Two       |
      And the following complaint entries exist:
        | id | uri     | entry_type | status  | user_id | second_reviewer_id | resolution | is_important |
        | 1  | abc.com | URI/DOMAIN | PENDING | 2       | 1                  | FIXED      | true         |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see the radio with id "res-fixed-radio" checked
      And button with id "ce_submit_button" should be disabled
      When I click "#review_decline_radio"
      Then button with id "ce_submit_button" should be enabled
      When I click "#ce_submit_button"
      And I wait for "10" seconds
      Then I should see content "ASSIGNED" within "#complaint_entry_status"

    @javascript
    Scenario: An analyst should not commit a pending ticket as the Assignee without using Allow Self Review
      Given a user with role "webcat user" exists and is logged in
      And the following complaint entries exist:
      | id | uri     | entry_type | status  | user_id | resolution | is_important |
      | 1  | abc.com | URI/DOMAIN | PENDING | 1       | FIXED      | true         |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see the radio with id "res-fixed-radio" checked
      And button with id "ce_submit_button" should be disabled
      When I click "#review_commit_radio"
      Then button with id "ce_submit_button" should be disabled

    @javascript
    Scenario: An analyst should commit a pending ticket as the Assignee while using Allow Self Review
      Given a user with role "webcat user" exists and is logged in
      And the following users exist
      | display_name   |
      | User Two       |
      And the following complaint entries exist:
      | id | uri     | entry_type | status  | user_id | resolution | is_important |
      | 1  | abc.com | URI/DOMAIN | PENDING | 1       | FIXED      | true         |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see the radio with id "res-fixed-radio" checked
      And button with id "ce_submit_button" should be disabled
      When I click "#review_commit_radio"
      Then button with id "ce_submit_button" should be disabled
      When I click checkbox with id "self_review"
      Then button with id "ce_submit_button" should be enabled
      When I click "#ce_submit_button"
      And I wait for "10" seconds
      Then I should see content "COMPLETED" within "#complaint_entry_status"

    @javascript
    Scenario: An analyst should decline a pending ticket as the Assignee while using Allow Self Review
      Given a user with role "webcat user" exists and is logged in
      And the following users exist
      | display_name   |
      | User Two       |
      And the following complaint entries exist:
      | id | uri     | entry_type | status  | user_id | resolution | is_important |
      | 1  | abc.com | URI/DOMAIN | PENDING | 1       | FIXED      | true         |
      When I goto "/escalations/webcat/complaint_entries/1"
      Then I should see the radio with id "res-fixed-radio" checked
      And button with id "ce_submit_button" should be disabled
      When I click "#review_decline_radio"
      Then button with id "ce_submit_button" should be disabled
      When I click checkbox with id "self_review"
      Then button with id "ce_submit_button" should be enabled
      When I click "#ce_submit_button"
      And I wait for "10" seconds
      Then I should see content "ASSIGNED" within "#complaint_entry_status"

  Rule: Tickets declined in review should display the 'Reviewed' icon.

    @javascript
    Scenario: A Complaint Entry that is declined should then have the attribute 'was_dismissed: true'
      Given a user with role "webcat user" exists and is logged in
      And the following users exist
        | display_name   |
        | User Two       |
      And the following complaint entries exist:
        | id | uri     | entry_type | status  | user_id | reviewer_id | resolution | url_primary_category | resolution_comment  | is_important |
        | 1  | abc.com | URI/DOMAIN | PENDING | 2       | 1           | FIXED      | Animals and Pets     | Resolution Comment  | true         |
      When I goto "/escalations/webcat/complaint_entries/1"
      And I wait for "2" seconds
      Then I should see the radio with id "res-fixed-radio" checked
      And I should see content "PENDING" within "#complaint_entry_status"
      And button with id "ce_submit_button" should be disabled
      When I click "#review_decline_radio"
      Then button with id "ce_submit_button" should be enabled
      When I click "#ce_submit_button"
      And I wait for "10" seconds
      Then I should see content "ASSIGNED" within "#complaint_entry_status"
      Then I should see element ".was-reviewed"

 Rule: Only WebCat Complaints from Talos Intelligence can convert to WebRep Disputes

    @javascript
    Scenario: A Complaint from talos intelligence should convert to a Dispute.
      Given a user with role "webcat user" exists and is logged in
      And the following complaints exist:
        | id | description        |  submitter_type | ticket_source      | status |
        | 1  | weather            |  CUSTOMER       | talos-intelligence | NEW    |
      And the following complaint entries exist:
        | id | uri     | entry_type | status | user_id | complaint_id |
        | 1  | abc.com | URI/DOMAIN | NEW    | 2       | 1            |
      When I goto "/escalations/webcat/complaint_entries/1"
      And I click "#convert-ticket-button"
      And I fill in element "#convert-ticket-summary" with "Test ticket summary."
      And I click "#web-ticket-type"
      And I wait for "2" seconds
      And I click input with id "1-fp-radio"
      And I click "#convert-to-webrep"
      And I wait for "2" seconds
      Then I should see an element ".success-msg" with text "Complaint converted to Reputation Dispute."

    @javascript
    Scenario: A Complaint not from talos intelligence should not convert to a Dispute.
      Given a user with role "webcat user" exists and is logged in
      And the following complaints exist:
        | id | description        |  submitter_type | ticket_source          | status |
        | 1  | weather            |  CUSTOMER       | not-talos-intelligence | NEW    |
      And the following complaint entries exist:
        | id | uri     | entry_type | status | user_id | complaint_id |
        | 1  | abc.com | URI/DOMAIN | NEW    | 2       | 1            |
      When I goto "/escalations/webcat/complaint_entries/1"
      And I click "#convert-ticket-button"
      Then I should see an element ".error-msg" with text "The Complaint is not a customer ticket from talos-intelligence."
