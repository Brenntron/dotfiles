Feature: Webcat complaints
  In order to manage web cat complaints
  I will provide a complaints interface

  Background:
    Given a guest company exists

  #TODO: we need to update the user role on these tests

#  @javascript
#  Scenario: a user should be alerted of impending doom
#    Given a user with role "webcat user" exists and is logged in
#    And the following complaint entries exist:
#      |id|  domain      | status |
#      |1 | food.com     |  NEW   |
#      |2 | blah.com     |  NEW   |
#      |3 | imhungry.com |  NEW   |
#    And a complaint entry preload exists
#    And I goto "/escalations/webcat/complaints?f=ALL"
#    And I wait for "2" seconds
#    And I click ".expand-row-button-1"
#    And I wait for "2" seconds
#    And I click ".expand-row-button-2"
#    And I wait for "2" seconds
#    And I fill in "complaint_comment_1" with "This is my favorite website"
#    And I fill in "complaint_comment_2" with "This is not my favorite website"
#    And I fill in "input_cat_1-selectized" with "Arts" and press enter
#    And I fill in "input_cat_2-selectized" with "Education" and press enter
#    And I wait for "2" seconds
#    When I click "master-submit"
#    Then I should see hidden element "#message-text" with content "I noticed you have made changes to at least 2 complaints but you only have 1 items selected."

  @javascript
  Scenario: a user can manually create a new complaint
    Given a user with role "webcat user" exists and is logged in
    And bugzilla rest api always saves
    And complaint entry preload is stubbed
    And WBRS top url is stubbed
    And WBRS Prefix where is stubbed
    And the following companies exist:
    | name  |
    | Cisco |
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
    And I click "Create"
    And I wait for "5" seconds
    And take a screenshot
    And I should see "COMPLAINT CREATED"
    And I click ".close"
    Then I wait for "10" seconds
    And I should see "urgent"

  @javascript
  Scenario: a user can manually create a new complaint that is uppercased and the path will become lowercased
    Given a user with role "webcat user" exists and is logged in
    And bugzilla rest api always saves
    And complaint entry preload is stubbed
    And WBRS top url is stubbed
    And WBRS Prefix where is stubbed
    And the following companies exist:
      | name  |
      | Cisco |
    And the following customers exist:
      | company_id | name         | email           |
      | 1          | Talos Person | talos@cisco.com |
    And a complaint entry with trait "new_entry" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#new-complaint"
    And I fill in "ips_urls" with "TalosIntelligence.com/my_FUNKY_url?is=Baller"
    And I fill in "description" with "This is my favorite website"
    And I fill in "customers" with "Cisco:Talos Person:talos@cisco.com"
    And I fill in selectized with "urgent"
    And I click "Create"
    And I wait for "5" seconds
    And I should see "COMPLAINT CREATED"
    And I click ".close"
    Then I wait for "10" seconds
    And I should see "talosintelligence.com"

  @javascript
  Scenario: a user can manually create a new complaint
    Given a user with role "webcat user" exists and is logged in
    And bugzilla rest api always saves
    And complaint entry preload is stubbed
    And WBRS top url is stubbed
    And WBRS Prefix where is stubbed
    And the following companies exist:
    | name  |
    | Cisco |
    And the following customers exist:
    | company_id | name         | email           |
    | 1          | Talos Person | talos@cisco.com |
    And the following platforms exist:
    | public_name |
    | FirePower   |
    And a complaint entry with trait "new_entry" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#new-complaint"
    And I fill in "ips_urls" with "talosintelligence.com"
    And I fill in "description" with "This is my favorite website"
    And I fill in "customers" with "Cisco:Talos Person:talos@cisco.com"
    And I fill in "platforms" with "FirePower"
    And I click "Create"
    And I wait for "5" seconds
    And I should see "COMPLAINT CREATED"
    # And I should see "FirePower" this line is commented until the page will display platform name



  # TODO write this test
  # Scenario: a user tries to take multiple complaints one of which is invalid


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
  Scenario: a user visits a complaint show page and sees its IP
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
    |id|ip_address|domain|
    |1 |1.2.3.4   |      |
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints/1"
    Then I should see "1.2.3.4"





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
#    And I click ".expand-row-button-inline"
    And I wait for "8" seconds
    Then I should see content "Nature and Conservation" within first element of class ".sds_category"

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
  Scenario: a user submits multiple entries and includes an internal and resolution comment
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      |id| domain        | status |
      |1 | blah.com      | NEW    |
      |2 | food.com      | NEW    |
      |3 | im.hungry.com | NEW    |
    When I goto "/escalations/webcat/complaints"
    And I click "#complaints_select_all"
    And I click "#index_update_resolution"
    And I select "Unchanged" from "complaint_resolution"
    And I fill in element "#internal_comment" with "Cisco"
    And I fill in element "#customer_facing_comment" with "Disco"
    And I click "#button_update_resolution"
    And I wait for "4" seconds
    And I should see "Set the following 3 entries to RESOLUTION UNCHANGED."
    And I click "#submit_resolution_changes"
    Then the following complaint entry with id: "1" has a resolution of: "UNCHANGED"
    Then the following complaint entry with id: "2" has a resolution of: "UNCHANGED"
    Then the following complaint entry with id: "3" has a resolution of: "UNCHANGED"
    Then the following complaint entry with id: "1" has a status of: "COMPLETED"
    Then the following complaint entry with id: "2" has a status of: "COMPLETED"
    Then the following complaint entry with id: "3" has a status of: "COMPLETED"
    Then the following complaint entry with id: "1" has a internal comment of: "Cisco"
    Then the following complaint entry with id: "2" has a internal comment of: "Cisco"
    Then the following complaint entry with id: "3" has a internal comment of: "Cisco"
    Then the following complaint entry with id: "1" has a resolution comment of: "Disco"
    Then the following complaint entry with id: "2" has a resolution comment of: "Disco"
    Then the following complaint entry with id: "3" has a resolution comment of: "Disco"

  @javascript
  Scenario: a user attempts to use Update Resolution on a Pending/Completed Complaint Entry, but INVALID and UNCHANGED are disabled from the drop-down menu
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      |id| domain   | uri            | status    | resolution | entry_type |
      |1 | blah.com | blah.com       | PENDING   | FIXED      | URI/DOMAIN |
      |2 | food.com | food.com       | COMPLETED | FIXED      | URI/DOMAIN |
    When I goto "/escalations/webcat/complaints"
    And I wait for "2" seconds
    And I click "#complaints_check_box"
    And I click "#index_update_resolution"
    And I wait for "4" seconds
    Then the "Unchanged" option from "complaint_resolution" is disabled
    Then the "Invalid" option from "complaint_resolution" is disabled
    Then the "Reopened" option from "complaint_resolution" is not disabled


  @javascript
  Scenario: a user uses the Update Resolution feature to reopen a completed ComplaintEntry
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      |id| domain            | status    |
      |1 | blah.com          | COMPLETED |
      |2 | food.com          | COMPLETED |
      |3 | im.hungry.com     | NEW       |
    When I goto "/escalations/webcat/complaints"
    And I click "#complaints_check_box"
    And I click "#index_update_resolution"
    And I select "Reopened" from "complaint_resolution"
    And I click "#button_update_resolution"
    And I wait for "5" seconds
    Then I should see "Set the following 2 entries to RESOLUTION REOPENED"
    When I click "#submit_resolution_changes"
    And I wait for "1" seconds
    Then the following complaint entry with id: "1" has a status of: "REOPENED"
    Then the following complaint entry with id: "2" has a status of: "REOPENED"
    Then the following complaint entry with id: "3" has a status of: "NEW"





  @javascript
  Scenario: left nav links should apply filter if the filter was set before
    Given a user with role "webcat user" exists and is logged in
    And a new complaint entry with trait "assigned_entry" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=MY%20COMPLAINTS"
    Then I wait for "3" seconds
    Then I should see "ASSIGNED"
    When I click "#nav-trigger-label"
    And I click "Escalations"
    And I click "#cat-icon-link"
    Then I wait for "3" seconds
    Then I should see "ASSIGNED"
    When I click "#nav-trigger-label"
    And I click "Escalations"
    And I click "#cat-link"
    Then I wait for "3" seconds
    Then I should see "ASSIGNED"

  @javascript
  Scenario: top nav links should apply filter if the filter was set before
    Given a user with role "webcat user" exists and is logged in
    And a new complaint entry with trait "assigned_entry" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=MY%20COMPLAINTS"
    Then I wait for "3" seconds
    Then I should see "ASSIGNED"
    When I click "#complaints"
    Then I wait for "3" seconds
    Then I should see "ASSIGNED"


  @javascript
  Scenario: user should get credit for direct categorizations for non-important urls
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I fill in "url_1" with "example123.com"
    And I fill in selectized with "Advertisements"
    And I click ".primary"
    And I wait for "10" seconds
    Then I should see "URLS CATEGORIZED SUCCESSFULLY"
    And I should see "No pending complaint entries have been created All other entries have been submitted directly to WBRS."
    Then I goto a "resolution" report surrounding the current year
    And I should see my username

  @javascript
  Scenario: user should see the link to refresh the page after categorization
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I fill in "url_1" with "example123.com"
    And I fill in selectized with "Advertisements"
    And I click ".primary"
    And I wait for "10" seconds
    Then I should see "URLS CATEGORIZED SUCCESSFULLY"
    And I should see "Refresh the page to see the result"
    Then I goto a "resolution" report surrounding the current year
    And I should see my username
