Feature: Webcat complaints
  In order to manage web cat complaints
  I will provide a complaints interface

  Background:
    Given a guest company exists


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





#  @javascript
#  Scenario: a users tries to update URI
#    Given a user with role "webcat user" exists and is logged in
#    And a complaint entry with trait "new_entry" exists
#    And a complaint entry preload exists
#    When I goto "/escalations/webcat/complaints?f=ALL"
#    And I click ".expand-row-button-inline"
#    And I fill in "complaint_prefix_1" with "cisco.com"
#    And I click ".inline-button"
#    And I wait for "10" seconds
#    And I goto "/escalations/webcat/complaints?f=ALL"
#    And I should see content "cisco.com" within "#domain_1"


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




