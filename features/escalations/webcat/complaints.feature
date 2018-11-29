Feature: Webcat complaints
  In order to manage web cat complaints
  I will provide a complaints interface

  #TODO: we need to update the user role on these tests

  @javascript
  Scenario: a user can manually create a new complaint
    Given a user with role "webcat user" exists and is logged in
    And the following companies exist:
    |id| name  |
    | 1| Cisco |
    And the following customers exist:
    | company_id | name         | email           |
    | 1          | Talos Person | talos@cisco.com |
    And a complaint entry with trait "new_entry" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#new-complaint"
    And I fill in "ips_urls" with "talosintelligence.com"
    And I fill in "description" with "This is my favorite website"
    And I fill in "customers" with "Cisco:Talos Person:talos@cisco.com"
    And I fill in selectized with "urgent"
    And I click "Create"
    And I wait for "30" seconds
    And I should see "COMPLAINT CREATED"

  @javascript
  Scenario: A user must review a high telemetry site
    Given a user with role "webcat user" exists and is logged in
    And a complaint entry with trait "high_telemetry" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=ALL"
    Then I wait for "7" seconds
    And I should see "Arts"
    Then I should not see "Update"
    And I click ".expand-all"
    Then I should see "Commit"
    Then I should see "Decline"
    Then I should see "Submit"

  @javascript
  Scenario: A user does not need to review a low telemetry site
    Given a user with role "webcat user" exists and is logged in
    And a complaint entry with trait "not_important" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=ALL"
    Then I should not see "Update"
    And I click ".expand-all"
    And I choose "fixed1"
    And I should see "Update"
    And I should not see "commit"
    When I click "#submit_changes_1"
    Then I should not see "commit"

  @javascript
  Scenario: a user can take a complaint
    Given a user with role "webcat user" exists and is logged in
    And a new complaint entry with trait "not_important" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "3" seconds
    And I click ".sorting_1"
    And I click ".take-ticket-toolbar-button"
    Then I wait for "3" seconds
    Then I should see "ASSIGNED"

  @javascript
  Scenario: a user can return a complaint
    Given a user with role "webcat user" exists and is logged in
    And an assigned complaint entry with trait "assigned_entry" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "3" seconds
    And I click ".sorting_1"
    And I click ".return-ticket-toolbar-button"
    And I goto "/escalations/webcat/complaints?f=ALL"
    Then I should see "NEW"

  @javascript
  Scenario: a user selects the 'My Complaints' filter
    Given a user with role "webcat user" exists and is logged in
    And a new complaint entry with trait "assigned_entry" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=MY%20COMPLAINTS"
    Then I wait for "3" seconds
    Then I should see "ASSIGNED"

  @javascript
  Scenario: a user selects the 'My Open Complaints' filter
    Given a user with role "webcat user" exists and is logged in
    And a new complaint entry with trait "assigned_entry" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=MY%20OPEN%20COMPLAINTS"
    Then I wait for "3" seconds
    Then I should see "ASSIGNED"

  @javascript
  Scenario: a user selects the 'My Closed Complaints' filter
    Given a user with role "webcat user" exists and is logged in
    And a new complaint entry with trait "assigned_closed_entry" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=MY%20CLOSED%20COMPLAINTS"
    Then I wait for "3" seconds
    Then I should see "COMPLETED"

  @javascript
  Scenario: a user selects the 'Completed' filter
    Given a user with role "webcat user" exists and is logged in
    And a new complaint entry with trait "completed_entry" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=COMPLETED"
    Then I wait for "3" seconds
    Then I should see "COMPLETED"

  @javascript
  Scenario: a user selects the 'Active' filter
    Given a user with role "webcat user" exists and is logged in
    And a new complaint entry with trait "pending_entry" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=ACTIVE"
    Then I wait for "3" seconds
    Then I should see "PENDING"

  @javascript
  Scenario: a user selects the 'New' filter
    Given a user with role "webcat user" exists and is logged in
    And a new complaint entry with trait "new_entry" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=NEW"
    Then I wait for "3" seconds
    Then I should see "NEW"

  @javascript
  Scenario: a user selects the 'Review' filter
    Given a user with role "webcat user" exists and is logged in
    And a new complaint entry with trait "pending_entry" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=REVIEW"
    Then I wait for "3" seconds
    Then I should see "PENDING"

  @javascript
  Scenario: a user selects the 'All' filter
    Given a user with role "webcat user" exists and is logged in
    And a new complaint entry with trait "assigned_entry" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=ALL"
    Then I wait for "3" seconds
    Then I should see "ASSIGNED"

  @javascript
  Scenario: a user attempts to view reports more than once
    Given an admin user with role "webcat user" exists and is logged in
    And I goto "/escalations/webcat/reports"
    And I fill in "complaint_entry_report_from" with "2018-08-01"
    And I fill in "complaint_entry_report_to" with "2018-08-02"
    Then I click "#complaint_entry_report" and switch to the new window
    Then I should see "Webcat Complaint Entry Report"
    Then I goto "/escalations/webcat/reports"
    And I fill in "complaint_entry_report_from" with "2018-08-11"
    And I fill in "complaint_entry_report_to" with "2018-08-12"
    Then I click "#complaint_entry_report" and switch to the new window
    Then I should see "Webcat Complaint Entry Report"
    
  @javascript
  Scenario: a user attempts to submit changes without categories and receives expected error alert
    Given a user with role "webcat user" exists and is logged in
    And a complaint entry with trait "new_entry" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "5" seconds
    And I click ".expand-all"
    And I wait for "5" seconds
    And I click "#submit_changes_1"
    And I wait for "5" seconds
    Then I should see "MUST INCLUDE AT LEAST ONE CATEGORY."

  @javascript
  Scenario: a user clicks the domain button
    Given a user with role "webcat user" exists and is logged in
    And a complaint entry with trait "new_entry" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "5" seconds
    And I click ".expand-all"
    And I wait for "5" seconds
    Then I click "#domain-1"
    Then I should see "Domain Information"

  @javascript
  Scenario: a user visits a complaint show page and sees its IP
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
    |id|domain|
    |1 |      |
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints/1"
    Then I should see "1.1.1.1"

  @javascript
  Scenario: lookup information is accessable via lookup button
    Given a user with role "webcat user" exists and is logged in
    And a new complaint entry with trait "new_entry" exists
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I resize the browser to "1440" X "768"
    And I wait for "5" seconds
    And I click button with class "expand-row-button-inline"
    Then I should not see "Lookup Information"
    And I wait for "5" seconds
    When I click "Lookup"
    Then I should see "Lookup Information"

  @javascript
  Scenario: a user sees a description in the 'Customer Description' field after selecting a complaint entry row
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
    |id|
    |1 |
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I click ".expand-all"
    Then I should see "Description for testing"

  @javascript
  Scenario: a users tries to categorize a URL
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I fill in "url_1" with "cisco.com"
    And I fill in selectized with "Adult"
    And I click ".primary"
    And I wait for "45" seconds
    Then I should see "URLS CATEGORIZED SUCCESSFULLY"
    And I should see "Categorization of a Top URL will create a pending complaint entry. All other entries have been submitted directly to WBRS."

  @javascript
  Scenario: a users tries to categorize without selecting a category
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I fill in "url_1" with "cisco.com"
    And I click ".primary"
    Then I should see "UNABLE TO CATEGORIZE"
    And I should see "Please confirm that a URL and at least one category for each desired entry exists."

  @javascript
  Scenario: a users tries to categorize without an URL
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I fill in selectized with "Adult"
    And I click ".primary"
    Then I should see "UNABLE TO CATEGORIZE"
    And I should see "Please confirm that a URL and at least one category for each desired entry exists."

  @javascript
  Scenario: a users tries to categorize a URL with an empty form
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I click ".primary"
    Then I should see "UNABLE TO CATEGORIZE"
    And I should see "Please confirm that a URL and at least one category for each desired entry exists."

  @javascript
  Scenario: a users tries submits a multiple url categorization
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I click "#cat-urls-same"
    And I fill in "categorize_urls" with "cisco.com" and "google.com" separated by blank lines
    And I fill in selectized with "Adult"
    And I trigger-click ".primary"
    And I wait for "60" seconds
    Then take a screenshot
    Then I should see "SUCCESS"
    Then I should see "URLs/IPs successfully categorized."

  @javascript
  Scenario: a users tries submits a multiple url categorization without a URL
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I click "#cat-urls-same"
    And I fill in selectized with "Adult"
    And I trigger-click ".primary"
    And I wait for "60" seconds
    Then I should see "ERROR"
    Then I should see "Please check that a URL/IP has been inputted and that at least one category was selected."

  @javascript
  Scenario: a users tries submits a multiple url categorization without a category
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I click "#cat-urls-same"
    And I fill in "categorize_urls" with "cisco.com" and "google.com" separated by blank lines
    And I trigger-click ".primary"
    Then I should see "ERROR"
    Then I should see "Please check that a URL/IP has been inputted and that at least one category was selected."

