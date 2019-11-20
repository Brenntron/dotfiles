Feature: Webcat complaints
  In order to manage web cat complaints
  I will provide a complaints interface

  Background:
    Given a guest company exists

  #TODO: we need to update the user role on these tests

  @javascript
  Scenario: a user can manually create a new complaint
    Given a user with role "webcat user" exists and is logged in
    And bugzilla rest api always saves
    And complaint entry preload is stubbed
    And WBRS top url is stubbed
    And WBRS Prefix where is stubbed
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
    And I wait for "5" seconds
    And I should see "COMPLAINT CREATED"
    And I click ".close"
    Then I wait for "5" seconds
    And I should see "urgent"

  @javascript
  Scenario: A user must review a high telemetry site
    Given a user with role "webcat user" exists and is logged in
    And a complaint entry with trait "high_telemetry" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=ALL"
    Then I wait for "3" seconds
    And I should see "Arts"
    Then I should not see "Update"
    And I click ".expand-row-button-inline"
    Then I wait for "3" seconds
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
    And I click ".expand-row-button-inline"
    And I wait for "5" seconds
    And I click "#fixed1"
    And I should see "Update"
    And I should not see "commit"
    When I click "#submit_changes_1"
    Then I should not see "commit"

  @javascript
  Scenario: a user can open selected ips in new tabs
    Given a user with role "webcat user" exists and is logged in
    And a complaint entry with trait "not_important" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=ALL"
    Then I select row "1"
    When I click "Open Selected"
    And I wait for "4" seconds
    Then a new window should be opened
    When I switch to the new window
    And I should see "Company news"



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
  Scenario: a user tries to take multiple complaints one of which is invalid
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      |id|  domain      |
      |1 | blah.com     |
      |2 | food.com     |
      |3 | im.hungry.com     |
    And a complaint entry preload exists
    Then pending

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

  # Test should work after WEB-5072 is complete
  @javascript
  Scenario: a user attempts to submit changes without categories and receives expected error alert
    Given a user with role "webcat user" exists and is logged in
    And a complaint entry with trait "new_entry" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "5" seconds
    And I click ".expand-row-button-inline"
    And I wait for "5" seconds
    And I click "#submit_changes_1"
    And I wait for "5" seconds
    Then I should see "MUST INCLUDE AT LEAST ONE CATEGORY."

  # Test should work after WEB-5001 is merged
  @javascript
  Scenario: a user attempts to submit changes with resolution set to 'Unchanged'
    Given a user with role "webcat user" exists and is logged in
    And a complaint entry with trait "new_entry" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "5" seconds
    And I click ".expand-row-button-inline"
    And I wait for "5" seconds
    And I click "#unchanged1"
    And I click "#submit_changes_1"
    And I wait for "5" seconds
    Then I should see "COMPLETED"

  @javascript
  Scenario: a user clicks the domain button
    Given a user with role "webcat user" exists and is logged in
    And a complaint entry with trait "new_entry" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "5" seconds
    And I click ".expand-row-button-inline"
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
    Then take a screenshot
    Then I should see "8.8.8.8"

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
    And I click ".expand-row-button-inline"
    Then I should see "Description for testing"

  @javascript
  Scenario: a user looks up a complaint's entry history without entering a URL
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I click "#history-1"
    Then I should see content "No data available for blank URL." within "#cat-url-1"

  @javascript
  Scenario: a user looks up a complaint's entry history with a valid URL
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I fill in "url_1" with "cisco.com"
    And I click "#history-1"
    And I wait for "5" seconds
    Then I should see "History Information"
    And I should see "DOMAIN HISTORY"
    And I should see "Tue, 12 May 2015 17:39:53 GMT"

  # Test should work after WEB-5077 is complete
  @javascript
  Scenario: a user looks up a complaint's entry history with an invalid URL
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I fill in "url_1" with "fmasoifkis.com"
    And I click "#history-1"
    And I wait for "5" seconds
    Then I should see "No history associated with this url."

  # Test should work after WEB-5077 is complete
  @javascript
  Scenario: a user looks up a complaint's entry history with an invalid URL in the third position (make sure that the notification appears in the right spot)
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    When I click "#categorize-urls"
    And I fill in "url_3" with "fmasoifkis.com"
    And I click "#history-3"
    And I wait for "5" seconds
    Then I should see content "No history associated with this url." within "#cat-url-3"

  @javascript
  Scenario: a users tries to categorize a URL
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I fill in "url_1" with "mary.com"
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
    And I fill in "categorize_urls" with "joseph.com" and "mary.com" separated by blank lines
    And I fill in selectized with "Adult"
    And I click "#cat-urls-same"
    And I click ".primary"
    And I wait for "20" seconds
    Then I should see "SUCCESS"
    And I should see "URLs/IPs successfully categorized."

  @javascript
  Scenario: a users tries submits a multiple url categorization without a URL
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I click "#cat-urls-same"
    And I fill in selectized with "Adult"
    And I click "#cat-urls-same"
    And I click ".primary"
    Then I should see "ERROR"
    Then I should see "Please check that a URL/IP has been inputted and that at least one category was selected."

  @javascript
  Scenario: a users tries submits a multiple url categorization without a category
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I click "#cat-urls-same"
    And I fill in "categorize_urls" with "cisco.com"
    And I click ".primary"
    Then I should see "ERROR"
    Then I should see "Please check that a URL/IP has been inputted and that at least one category was selected."

  @javascript
  Scenario: a users tries to fetch complaints
    Given a user with role "webcat user" exists and is logged in
    And PeakeBridge poll is stubbed
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#fetch"
    Then I wait for "3" seconds
    Then I should see "COMPLAINT UPDATES REQUESTED FROM TALOS-INTELLIGENCE.  PLEASE REFRESH YOUR PAGE SHORTLY."

  @javascript
  Scenario: a users tries to lookup categories for a URL
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I fill in "url_1" with "chabad.org"
    And I click ".current-categories-button"
    Then I wait for "5" seconds

  @javascript
  Scenario: a users tries to lookup categories for a URL that has a categorized subdomain and a uncategorized domain
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I fill in "url_1" with "trial.superduperreallyfakeamazing.com"
    And I click ".current-categories-button"
    And I wait for "5" seconds
    Then I should see content "Religion" within ".item"
    And I fill in "url_1" with "superduperreallyfakeamazing.com"
    And I click ".current-categories-button"
    And I wait for "5" seconds
    Then I should not see div element with class ".item"

  @javascript
  Scenario: a users tries to drop current categories on a URL
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I fill in "url_1" with "washingtonpost.com"
    And I click ".delete-categories-button"
    And I wait for "10" seconds
    Then I should see "Categories successfully dropped."

  @javascript
  Scenario: a users tries to fetch WBNP data
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#fetch_wbnp"
    And I wait for "10" seconds
    Then I should see content "Active" within ".wbnp-report-status"

  @javascript
  Scenario: a users tries to update URI
    Given a user with role "webcat user" exists and is logged in
    And a complaint entry with trait "new_entry" exists
    And a complaint entry preload exists
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click ".expand-row-button-inline"
    And I fill in "complaint_prefix_1" with "cisco.com"
    And I click ".inline-button"
    And I wait for "10" seconds
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I should see content "cisco.com" within "#domain_1"


  # This will eventually need to be stubbed, because the response from SDS might update
  @javascript
  Scenario: a user expands a Complaint Entry and sees SDS data when WBRS data is not present
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
    | uri             | domain        | subdomain | path | entry_type |
    | baumpflege.ac   | baumpflege.ac |           |      | URI/DOMAIN |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click ".expand-row-button-inline"
    And I wait for "8" seconds
    Then I should see content "Nature" within ".sds_category"


  @javascript
  Scenario: when a complaint in the WBNP queue is resolved,
            a bridge message should not be sent
    Given a user with role "webcat user" exists and is logged in
    And the following complaints exist:
      | ticket_source | id | status |
      | RuleUI        | 1  | NEW    |
    And the following complaint entries exist:
      | uri             | domain        | subdomain | path | entry_type | complaint_id |
      | baumpflege.ac   | baumpflege.ac |           |      | URI/DOMAIN |  1           |
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "5" seconds
    And I click ".expand-row-button-inline"
    And I wait for "5" seconds
    And I click "#unchanged1"
    And I click "#submit_changes_1"
    And I wait for "5" seconds
    Then I should see "COMPLETED"
    And "0" bridge message should be in the delayed job queue


  @javascript
  Scenario: when a complaint in the talos-intelligence queue is resolved,
  a bridge message should be sent via delayed jobs
    Given a user with role "webcat user" exists and is logged in
    And the following complaints exist:
      | ticket_source             | id | status |
      | talos-intelligence        | 1  | NEW    |
    And the following complaint entries exist:
      | uri             | domain        | subdomain | path | entry_type | complaint_id |
      | baumpflege.ac   | baumpflege.ac |           |      | URI/DOMAIN |  1           |
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "5" seconds
    And I click ".expand-row-button-inline"
    And I wait for "5" seconds
    And I click "#unchanged1"
    And I click "#submit_changes_1"
    And I wait for "5" seconds
    Then I should see "COMPLETED"
    And "1" bridge message should be in the delayed job queue

  @javascript
  Scenario: a user clicks the "Pin Toolbar" button and sees the toolbar docked to the top navbar
    Given a user with role "webcat user" exists and is logged in
    And the following complaints exist:
      | ticket_source             | id | status |
      | talos-intelligence        | 1  | NEW    |
    And the following complaint entries exist:
      | uri             | domain        | subdomain | path | entry_type | complaint_id | status |
      | abc.com         | abc.com       |           |      | URI/DOMAIN |  1           | NEW    |
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints"
    And I click "#pin-to-top"
    Then I should not see "Pin Toolbar"
    And I click "#pin-to-top"
    Then I should see "Pin Toolbar"

  @javascript
  Scenario: a user types the hot key/shortcut to pin the toolbar to top and sees the toolbar docked
    Given a user with role "webcat user" exists and is logged in
    And the following complaints exist:
      | ticket_source             | id | status |
      | talos-intelligence        | 1  | NEW    |
    And the following complaint entries exist:
      | uri             | domain        | subdomain | path | entry_type | complaint_id | status |
      | abc.com         | abc.com       |           |      | URI/DOMAIN |  1           | NEW    |
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints"
    And I enter the pin toolbar hot key
    Then I should not see "Pin Toolbar"

  # webcat > complaints index > new banner w/ metrics
  @javascript
  Scenario: a user sees there is new/assigned Talos/WBNP/internal complaints in webcat index top banner
    Given a user with role "webcat user" exists and is logged in
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
      | uri            | domain          | entry_type | complaint_id | status     |
      | abc.com        | abc.com         | URI/DOMAIN |  1           | NEW        |
      | whatever.com   | whatever.com    | URI/DOMAIN |  2           | NEW        |
      | url.com        | url.com         | URI/DOMAIN |  3           | ASSIGNED   |
      | test.com       | test.com        | URI/DOMAIN |  4           | ASSIGNED   |
      | something.com  | something.com   | URI/DOMAIN |  5           | NEW        |
      | yadayada.com   | yadayada.com    | URI/DOMAIN |  6           | NEW        |
      | nothing.com    | nothing.com     | URI/DOMAIN |  7           | ASSIGNED   |
      | something.com  | something.com   | URI/DOMAIN |  8           | NEW        |
      | blahblah.com   | blahblah.com    | URI/DOMAIN |  9           | ASSIGNED   |
    And I goto "/escalations/webcat/complaints"
    And I wait for "1" seconds
    Then I should see content "2" within "#ti-new-count"
    Then I should see content "2" within "#ti-assigned-count"
    Then I should see content "2" within "#wbnp-new-count"
    Then I should see content "1" within "#wbnp-assigned-count"
    Then I should see content "1" within "#int-new-count"
    Then I should see content "1" within "#int-assigned-count"

  # webcat > complaints index > take a ticket, test assigned metric updates
  @javascript
  Scenario: a user sees a new complaint metric after making a New on webcat index, then takes ticket to see its assigned
    Given a user with role "webcat user" exists and is logged in
    And bugzilla rest api always saves
    And I goto "/escalations/webcat/complaints"
    And I wait for "5" seconds
    And I click "#new-complaint"
    And I fill in "ips_urls" with "example.com"
    And I click ".primary"
    And I wait for "5" seconds
    And I click ".close"
    And I wait for "3" seconds
    And I click ".sorting_1"
    And I click ".take-ticket-toolbar-button"
    And I wait for "3" seconds
    Then I should see content "1" within "#int-assigned-count"
