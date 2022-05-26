Feature: Disputes
  In order to interact with disputes
  as a user
  I will provide ways to interact with disputes

  @javascript
  Scenario: A user can create a new SDR Dispute
    Given a user with role "webrep user" exists and is logged in
    Given the following SDR disputes exist:
      | id |
      | 1  |
    And the following platforms exist:
    | public_name |
    | FirePower   |
    Given a dispute exists and is related to disputes with ID, "1":
    When I go to "/escalations/sdr/disputes"
    And I wait for "2" seconds
    Then I click "#new-sdr-dispute"
    And I fill in element, "#sender" with "cisco.com"
    And I select "P1" from "priority"
    And I select "False Positive" from "reputation"
    And I fill in "platforms" with "FirePower"
    And I fill in "customers" with "Bobs Burgers:Bob Jones:bob@bob.com"
    And I fill in "details" with "Test Details."
    When I click "submit"
    Then I wait for "2" seconds
    Then I should see "DISPUTE CREATED"

  @javascript
  Scenario: the submitted at field returns data
    Given a user with role "admin" exists and is logged in
    And the following SDR disputes exist:
      | id |
      | 1  |
      | 2  |
    Then I go to "/escalations/sdr/disputes/1"
    Then Expect date in element ".submitted-time" to equal today's date

  @javascript
  Scenario: a user can see data in the Submitter Type column
    Given a user with role "webrep user" exists and is logged in
    And the following SDR disputes exist:
      | id | submitter_type |
      | 1  | CUSTOMER       |
    Then I goto "escalations/sdr"
    Then I wait for "2" seconds
    When I click "#table-show-columns-button"
    And I click "#submitter-type-checkbox"
    Then I should see table header with id "submitter-type"
    Then I should see "CUSTOMER"

  @javascript
  Scenario: a user takes a dispute and status is updated to assigned
    Given a user with role "webrep user" exists with cvs_username, "Cucumber", exists and is logged in
    Given the following users exist
      | id | cvs_username |
      | 3  | vrtincom     |
    And the following SDR disputes exist:
      | id | user_id |
      | 2  | 3       |
      | id | user_id |
      | 3  | 3       |
    When I goto "escalations/sdr/disputes"
    And I click ".inline-take-dispute-3"
    Then I see "ASSIGNED" in element "#status_3"
    Then I should see user, "Cucumber", in element "#owner_3"
    And I click "#cbox2"
    And I click "#index_ticket_assign"
    Then I see "ASSIGNED" in element "#status_2"
    Then I should see user, "Cucumber", in element "#owner_2"

  @javascript
  Scenario: a user takes a dispute, returns a dispute, and takes the dispute again
    Given a user with role "webrep user" exists with cvs_username, "Cucumber", exists and is logged in
    Given the following users exist
      | id | cvs_username |
      | 3  | vrtincom     |
    And the following SDR disputes exist:
      | id | user_id |
      | 2  | 3       |
    When I goto "escalations/sdr/disputes"
    And I click ".inline-take-dispute-2"
    Then I see "ASSIGNED" in element "#status_2"
    Then I see "Cucumber" in element "#owner_2"
    And I click ".inline-return-ticket-2"
    Then I see "NEW" in element "#status_2"
    Then I see "Unassigned" in element "#owner_2"
    When I click ".inline-take-dispute-2"
    Then I see "ASSIGNED" in element "#status_2"
    Then I see "Cucumber" in element "#owner_2"

  @javascript
  Scenario: when the user encounters a situation in which no results exists (therefore none returned), an error modal should display
    Given a user with role "webrep user" exists and is logged in
    When I goto "escalations/sdr/disputes"
    Then I should see "No data available in table"

  @javascript
  Scenario: a user adds and selects columns from the Column drop-down
    Given a user with role "webrep user" exists and is logged in
    And the following SDR disputes exist:
      | id |
      | 1  |
    When I goto "escalations/sdr/disputes?f=open"
    And I wait for "3" seconds
    And I click "#table-show-columns-button"
    And I click "#case-id-checkbox"
    And I click "#status-checkbox"
    And I click "#submitter-type-checkbox"
    And I click "#submitter-org-checkbox"
    And I click "#contact-name-checkbox"
    And I click "#contact-email-checkbox"
    When I goto "escalations/sdr/disputes?f=open"
    Then I wait for "5" seconds
    Then I should not see "CASE ID"
    Then I should not see "STATUS"
    Then I should see "SUBMITTER TYPE"
    Then I should see "SUBMITTER ORG"
    Then I should see "CONTACT NAME"
    Then I should see "CONTACT EMAIL"

  @javascript
  Scenario: a user uses advanced search with 'Contact Email' as a search criteria
    Given a user with role "webrep user" exists and is logged in
    And the following SDR disputes exist:
      | id |
      | 1  |
    When I goto "escalations/sdr/disputes?f=all"
    And I click "#table-show-columns-button"
    And I click "#contact-email-checkbox"
    And I click "#table-show-columns-button"
    And I click "#sdr-advanced-search-button"
    And I click "#add-search-items-button"
    And I click "#email-cb"
    Then I click "#cancel-add-criteria"
    Then I fill in "email-input" with "bob@bob.com"
    Then I click "#submit-advanced-search"
    And I wait for "3" seconds
    Then I should see "test@google.com"
    Then I should see "0000000001"
    Then I should see "bob@bob.com"
    Then I should see "TI Webform"
    Then I should see "NEW"
    Then I should see "All"

  @javascript
  Scenario: a user uses advanced search with 'Platform' as a search criteria
    Given a user with role "webrep user" exists and is logged in
    And platforms with all traits exist
    Given the following SDR disputes exist:
      | id | platform_id |
      | 1  |  1          |
      | 2  |  2          |
      | 3  |  3          |
      | 4  |             |
      | 5  |  1          |
    When I goto "escalations/sdr/disputes?f=all"
    And I click "#sdr-advanced-search-button"
    And I click "#add-search-items-button"
    And I click "#platform-cb"
    And I wait for "5" seconds
    And I fill in selectized of element "#platform-input" with "['1', '2']"
    Then I click "#cancel-add-criteria"
    Then I click "#submit-advanced-search"
    Then I should see "0000000001"
    And I should see "0000000002"
    And I should not see "0000000003"
    And I should not see "0000000004"
    And I should see "0000000005"


  @javascript
  Scenario: a user wants to do an advanced search and ensure those previous values are cleared on subsequent search
    Given a user with role "webrep user" exists and is logged in
    Given the following SDR disputes exist:
      | id | status    | sender_domain_entry |
      | 1  | ESCALATED | test@cisco.com      |
      | 2  | PENDING   | test@google.com     |
    When I goto "escalations/sdr/disputes?f=all"
    And I should see "All Tickets"
    And I click "#sdr-advanced-search-button"
    And I should see "Advanced Search"
    And I fill in "status-input" with "ESCALATED"
    And I should see content "ESCALATED" within "#status-input"
    Then I click "#submit-advanced-search"
    And I wait for "3" seconds
    Then I should see "0000000001"
    Then I should see "ESCALATED"
    Then I should not see "0000000002"
    Then I should not see "PENDING"
    And I click "#sdr-advanced-search-button"
    And I click "#remove-criteria-status"
    And I click "#add-search-items-button"
    And I click "#status-cb"
    And I click "#cancel-add-criteria"
    And I should not see content "ESCALATED" within "#status-input"
    And I fill in "dispute-input" with "test@google.com"
    And I should see content "test@google.com" within "#dispute-input"
    Then I click "#submit-advanced-search"
    And I wait for "3" seconds
    Then I should see "0000000002"
    Then I should see "test@google.com"
    Then I should not see "ESCALATED"

  @javascript
  Scenario: A user creates a new named search for disputes
    Given a user with role "webrep user" exists and is logged in
    And the following SDR disputes exist:
      |  id  |  status  | user_id |
      | 5370 | ASSIGNED |    1    |
    When I goto "/escalations/sdr/disputes"
    And I click "#sdr-advanced-search-button"
    And I fill in "search_name" with "Lab"
    And I click "#submit-advanced-search"
    And I click "#sdr-filter-cases"
    Then I should see content "Lab" within "#saved-searches-wrapper"

  @javascript
  Scenario: A user uses a new named search for disputes
    Given a user with role "webrep user" exists and is logged in
    And the following SDR disputes exist:
      | id |     status      |
      |  1 |       NEW       |
      |  2 |       NEW       |
      |  3 | RESOLVED_CLOSED |
    And a named search with the name, "Cucumber" exists
    And a named search criteria exists with field_name: "status" and value: "NEW"
    When I goto "/escalations/sdr/disputes?f=closed"
    And  I wait for "3" seconds
    And  I should see content "RESOLVED_CLOSED" within "#status_3"
    Then I should not see "0000000001"
    And  I should not see content "NEW" within "#sdr-disputes-index"
    And  I should not see "0000000002"
    When I click "#sdr-filter-cases"
    And  I click ".saved-search"
    And  I wait for "3" seconds
    Then I should see "0000000001"
    And  I should see content "NEW" within "#status_1"
    And  I should see content "NEW" within "#status_2"
    And  I should see "0000000002"

  @javascript
  Scenario: A user creates a new named search for disputes
    Given a user with role "webrep user" exists and is logged in
    And the following SDR disputes exist:
      |  id  |  status  | user_id |
      | 5370 | ASSIGNED |    1    |
    When I goto "/escalations/sdr/disputes?f=open"
    And  I wait for "3" seconds
    And I click "#sdr-advanced-search-button"
    And I fill in "search_name" with "Cucumber"
    And I click "#submit-advanced-search"
    And I click "#sdr-filter-cases"
    Then I should see content "Cucumber" within "#saved-searches-wrapper"

  @javascript
  Scenario: A user creates a duplicate named search for disputes
    Given a user with role "webrep user" exists and is logged in
    And a named search with the name, "Cucumber" exists
    And a named search criteria exists with field_name: "status" and value: "NEW"
    And the following SDR disputes exist:
      |  id  |  status  | user_id |
      | 5370 | ASSIGNED |    1    |
    When I goto "/escalations/sdr/disputes?f=open"
    And  I wait for "3" seconds
    And I click "#sdr-advanced-search-button"
    And I fill in "search_name" with "Cucumber"
    And I click "#submit-advanced-search"
    And I click "#sdr-filter-cases"
    Then I should see content "Cucumber" within "#saved-searches-wrapper"
    And There is only one element of class, "saved-search"

  @javascript
  Scenario: A user creates a new named search for disputes and stays on the page (tests to make sure multiple named search criteria are not created)
    Given a user with role "webrep user" exists and is logged in
    And the following SDR disputes exist:
      |  id  |  status  | user_id |
      | 5370 | ASSIGNED |    1    |
    When I goto "/escalations/sdr/disputes?f=open"
    And  I wait for "3" seconds
    And I click "#sdr-advanced-search-button"
    And I fill in "search_name" with "Cucumber"
    And I click "#submit-advanced-search"
    And I click "#sdr-filter-cases"
    Then I should see content "Cucumber" within "#saved-searches-wrapper"

  @javascript
  Scenario: A user tries to update a dispute
    Given a user with role "webrep user" exists and is logged in
    And the following SDR disputes exist:
      | id   |
      | 5370 |
    When I goto "/escalations/sdr/disputes/5370"
    And I click "#show-edit-ticket-status-button"
    And I click "#ESCALATED"
    And I click ".primary"
    Then I should see content "Escalated" within "#show-edit-ticket-status-button"
    And I click "#show-edit-ticket-status-button"
    And I click "#RESEARCHING"
    And I click ".primary"
    Then I should see content "RESEARCHING" within "#show-edit-ticket-status-button"

  @javascript
  Scenario: A user can show and hide columns
    Given a user with role "webrep user" exists and is logged in
    And the following SDR disputes exist:
      | id |
      | 1  |
    When I goto "/escalations/sdr/disputes"
    Then I should see content "CASE ID" within "#case-id"
    When I click "#table-show-columns-button"
    And I toggle checkbox "#case-id-checkbox"
    And I toggle checkbox "#submitter-type-checkbox"
    Then I should see content "SUBMITTER TYPE" within "#submitter-type"
    Then I should not see element "#case-id"
