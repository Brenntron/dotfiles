Feature: Disputes
  In order to interact with disputes
  as a user
  I will provide ways to interact with disputes



  @javascript
  Scenario: a user visits the duplicate cases tab and sees a table of duplicate cases
    Given a user with role "webrep user" exists and is logged in
    Given the following disputes exist and have entries:
      | id |
      | 1  |
    Given a dispute exists and is related to disputes with ID, "1":
    And I go to "/escalations/webrep/disputes/1"
    Then I click "#related-tab-link"
    Then I should see "0000000002"

  @javascript
  Scenario: A user cannot create a duplicate url Dispute
    Given a user with role "webrep user" exists and is logged in
    Given the following disputes exist and have entries:
      | id |
      | 1  |
    Given a dispute exists and is related to disputes with ID, "1":
    When I go to "/escalations/webrep/disputes"
    And I wait for "2" seconds
    Then I click "new-dispute"
    And I fill in "ips_urls" with "talosintelligence.com"
    And I fill in "assignee" with "nherbert"
    When I click "submit"
    Then I should see "Unable to create the following duplicate dispute entries: talosintelligence.com"
    
  @javascript
  Scenario: A user cannot create a duplicate IP Dispute
    Given a user with role "webrep user" exists and is logged in
    Given the following disputes exist:
      | id |   subject     | status |
      | 1  |    test 2     |  NEW   |
    Given the following dispute_entries exist:
      | id |      ip_address     | status |
      | 1  | 123.63.22.24        |  NEW   |
    Given a dispute exists and is related to disputes with ID, "1":
    When I go to "/escalations/webrep/disputes"
    And I wait for "2" seconds
    Then I click "new-dispute"
    And I fill in "ips_urls" with "123.63.22.24"
    And I fill in "assignee" with "nherbert"
    When I click "submit"
    Then I should see "Unable to create the following duplicate dispute entries: 123.63.22.24"



  @javascript
  Scenario: the last submitted field returns data
    Given a user with role "admin" exists and is logged in
    And the following disputes exist and have entries:
      | id |
      | 1  |
      | 2  |
    Then I go to "/escalations/webrep/disputes/1"
    Then I click link "Research"
    Then Expect date in element "#last-submitted" to equal today's date

  @javascript
  Scenario: a user can see data in the Submitter Type column
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id | submitter_type |
      | 1  | CUSTOMER       |
    Then I goto "escalations/webrep/"
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
    And the following disputes exist:
      | id | user_id |
      | 2  | 3       |
    When I goto "escalations/webrep/disputes"
    And I click ".take-dispute-2"
    Then I see "ASSIGNED" in element "#status_2"
    Then I should see user, "Cucumber", in element "#owner_2"

  @javascript
  Scenario: a user takes a dispute, returns a dispute, and takes the dispute again
    Given a user with role "webrep user" exists with cvs_username, "Cucumber", exists and is logged in
    Given the following users exist
      | id | cvs_username |
      | 3  | vrtincom     |
    And the following disputes exist:
      | id | user_id |
      | 2  | 3       |
    When I goto "escalations/webrep/disputes"
    And I click ".take-dispute-2"
    Then I see "ASSIGNED" in element "#status_2"
    Then I see "Cucumber" in element "#owner_2"
    When I click ".return-ticket-2"
    Then I see "NEW" in element "#status_2"
    Then I see "Unassigned" in element "#owner_2"
    When I click ".take-dispute-2"
    Then I see "ASSIGNED" in element "#status_2"
    Then I see "Cucumber" in element "#owner_2"

  @javascript
  Scenario: a user edits a dispute entry's status and saves their changes
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id |
      | 1  |
    When I goto "escalations/webrep/disputes/1/"
    And I click "#research-tab-link"
    And I click ".inline-edit-entry-button"
    And I click "#entry_status_button_1"
    And I click "#RE-OPENED"
    And I click ".save-all-changes"
    Then I wait for "3" seconds
    Then I should see "RE-OPENED"

  @javascript
  Scenario: when the user encounters a situation in which no results exists (therefore none returned), an error modal should display
    Given a user with role "webrep user" exists and is logged in
    When I goto "escalations/webrep/disputes"
    Then I should see "NO TICKETS MATCHING FILTER OR SEARCH."

  @javascript
  Scenario: a user adds a dispute as a related case using the tooltip button
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
      | id |
      | 1  |
    And the following disputes exist:
      | id |
      | 2  |
    When I goto "escalations/webrep/disputes"
    And I wait for "2" seconds
    Given I check "cbox0000000001"
    And I click ".mark-related-button"
    And I fill in "dispute_id" with "2"
    And I click "#set-related-dispute-submit-button_button_related_dispute"
    And I wait for "5" seconds
    Then check if dispute id, "1", has a related_id of "2"

  @javascript
  Scenario: a user uses advanced search filter (Submitted Older/Modified Older) and exports to csv
    Given pending
    # Note that selenium doesn't support viewing response headers as is required by this test, maybe just get rid of it
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id |
      | 1  |
    When I goto "escalations/webrep/disputes?f=open"
    And I click "#advanced-search-button"
    And I click "#add-search-items-button"
    And I click "#submitted-older-cb"
    And I click "#modified-older-cb"
    And I click "#add-search-criteria"
    Then I click ".export-button"
    Then I wait for "3" seconds
    Then I should receive a file of type "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"'

  @javascript
  Scenario: a user adds and selects columns from the Column drop-down
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id |
      | 1  |
    When I goto "escalations/webrep/disputes?f=open"
    And I wait for "3" seconds
    And I click "#table-show-columns-button"
    And I click "#case-id-checkbox"
    And I click "#status-checkbox"
    And I click "#submitter-type-checkbox"
    And I click "#submitter-org-checkbox"
    And I click "#submitter-domain-checkbox"
    And I click "#contact-name-checkbox"
    And I click "#contact-email-checkbox"
    When I goto "escalations/webrep/disputes?f=open"
    Then I wait for "5" seconds
    Then I should not see "CASE ID"
    Then I should not see "STATUS"
    Then I should see "SUBMITTER TYPE"
    Then I should see "SUBMITTER ORG"
    Then I should see "SUBMITTER DOMAIN"
    Then I should see "CONTACT NAME"
    Then I should see "CONTACT EMAIL"

  @javascript
  Scenario: a users uses advanced search with 'Contact Name' as a search criteria
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id | submission_type |
      | 1  | w               |
    When I goto "escalations/webrep/disputes?f=all"
    And I click "#advanced-search-button"
    And I click "#add-search-items-button"
    And I click "#name-cb"
    And I click "#add-search-criteria"
    Then I fill in "name-input" with "Bob Jones"
    Then I click "#submit-advanced-search"
    And I wait for "5" seconds
    And I click "#advanced-search-button"
    Then I wait for "5" seconds
    Then I should see "talosintelligence.com"
    Then I should see "0000000001"


  @javascript
  Scenario: a users uses advanced search with 'Contact Email' as a search criteria
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id | submission_type |
      | 1  | w               |
    When I goto "escalations/webrep/disputes?f=all"
    And I click "#advanced-search-button"
    And I click "#add-search-items-button"
    And I click "#email-cb"
    And I click "#add-search-criteria"
    Then I fill in "email-input" with "bob@bob.com"
    Then I click "#submit-advanced-search"
    And I wait for "3" seconds
    And I click "#advanced-search-button"
    Then I wait for "5" seconds
    Then I should see "talosintelligence.com"
    Then I should see "0000000001"

  @javascript
  Scenario: a users uses advanced search with 'Company' as a search criteria
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id | submission_type |
      | 1  | w               |
    When I goto "escalations/webrep/disputes?f=all"
    And I click "#advanced-search-button"
    And I click "#add-search-items-button"
    And I click "#company-cb"
    And I click "#add-search-criteria"
    Then I fill in "company-input" with "Guest"
    Then I click "#submit-advanced-search"
    And I wait for "3" seconds
    And I click "#advanced-search-button"
    Then I wait for "5" seconds
    Then I should see "talosintelligence.com"
    Then I should see "0000000001"

  @javascript
  Scenario: a user tries to export selected dispute entries
    Given pending
    # Note that selenium doesn't support viewing response headers as is required by this test, maybe just get rid of it
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id | submission_type |
      | 1  | w               |
    When I goto "escalations/webrep/disputes?f=open"
    And I click ".dispute_check_box"
    And I click "Export Selected to CSV"
    Then I wait for "3" seconds
    Then I should receive a file of type "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"




  ### WBRS WL/BL Dropdown

  @javascript
  Scenario: a user wants to view the current WBRS lists and score for an entry from the index page
    Given a user with role "webrep user" exists and is logged in
    Given the following disputes exist:
      | id | submission_type |
      | 1  | w               |
    Given the following dispute_entries exist:
      | id | uri                   |
      | 1  | imadethisurlup.com    |
    # Adding this step below to ensure the api data is clear
    And  clean up wlbl and remove all wlbl entries on "imadethisurlup.com"
    When I goto "escalations/webrep/disputes?f=open"
    And  I wait for "2" seconds
    And  I click ".expand-row-button-inline"
    And  I click ".dispute-entry-checkbox"
    And  I click "#index-adjust-wlbl"
    And  I wait for "5" seconds
    Then I should see "Current WL/BL List"
    And  I should see "Current WBRS Score"
    And  I should see "Threat Category"
    And  I should see "Not on a list"
    And  I should see "No score"


  @javascript
  Scenario: a user adds an entry to a WBRS list from the index page
    Given a user with role "webrep user" exists and is logged in
    Given the following disputes exist:
      | id | submission_type |
      | 1  | w               |
    Given the following dispute_entries exist:
      | id | uri                |
      | 1  | imadethisurlup.com |
    When I goto "escalations/webrep/disputes?f=open"
    And  I wait for "2" seconds
    And  I click ".expand-row-button-inline"
    And  I click ".dispute-entry-checkbox"
    And  I click "#index-adjust-wlbl"
    And  I wait for "2" seconds
    And  I should see "Not on a list"
    And  I should see "No score"
    Then I click "#wlbl-add"
    And  I check checkbox with class "wl-med-checkbox"
    And  I click "#index-bulk-submit-wbrs"
    And  I wait for "10" seconds
    And  I should see "ENTRIES HAVE BEEN UPDATED"
    And  I click button with class "close"
    And  I wait for "1" seconds
#    And  take a screenshot
    And  I click "#index-adjust-wlbl"
    And  I wait for "2" seconds
    And  Element with class "wlbl-entry-wlbl" should have content "WL-med"
    And  clean up wlbl and remove all wlbl entries on "imadethisurlup.com"


  @javascript
  Scenario: a user removes an entry from a WBRS list from the index page
  #  after adding it so we're starting with clean data from the api
    Given a user with role "webrep user" exists and is logged in
    Given the following disputes exist:
      | id | submission_type |
      | 1  | w               |
    Given the following dispute_entries exist:
      | id | uri                |
      | 1  | imadethisurlup.com |
    When I goto "escalations/webrep/disputes?f=open"
    And  I wait for "2" seconds
    And  I click ".expand-row-button-inline"
    And  I click ".dispute-entry-checkbox"
    And  I click "#index-adjust-wlbl"
    And  I wait for "2" seconds
    And  I should see "Not on a list"
    Then I click "#wlbl-add"
    And  I check checkbox with class "wl-med-checkbox"
    And  I click "#index-bulk-submit-wbrs"
    And  I wait for "10" seconds
    And  I should see "ENTRIES HAVE BEEN UPDATED"
    And  I click button with class "close"
    And  I wait for "1" seconds
    And  I click "#index-adjust-wlbl"
    And  I wait for "2" seconds
    And  Element with class "wlbl-entry-wlbl" should have content "WL-med"
    Then I click "#wlbl-remove"
    And  I check checkbox with class "wl-med-checkbox"
    And  I click "#index-bulk-submit-wbrs"
    And  I wait for "10" seconds
    And  I should see "ENTRIES HAVE BEEN UPDATED"
    And  I click button with class "close"
    And  I wait for "1" seconds
#    And  take a screenshot
    And  I click "#index-adjust-wlbl"
    And  I wait for "2" seconds
    And  I should see "Not on a list"
    And  I should see "No score"
    And  Element with class "wlbl-entry-wlbl" should not have content "WL-med"
    And  clean up wlbl and remove all wlbl entries on "imadethisurlup.com"


  @javascript
  Scenario: a user adds an entry to a WBRS Blacklist from the index page
    Given a user with role "webrep user" exists and is logged in
    Given the following disputes exist:
      | id | submission_type |
      | 1  | w               |
    Given the following dispute_entries exist:
      | id | uri                |
      | 1  | imadethisurlup.com |
    When I goto "escalations/webrep/disputes?f=open"
    And  I wait for "2" seconds
    And  I click ".expand-row-button-inline"
    And  I click ".dispute-entry-checkbox"
    And  I click "#index-adjust-wlbl"
    And  I wait for "2" seconds
    And  Element with class "wlbl-entry-wlbl" should not have content "BL-weak"
    Then I click "#wlbl-add"
    And  I check checkbox with class "bl-weak-checkbox"
    And  I wait for "1" seconds
    And  I should see "Threat Categories"
    And  I should see "Required for adding to any blacklist."
    And  I should see "Bogon"
    And  I should see "Cryptojacking"
    And  I should see "Phishing"
    Then I click ".wlbl_thrt_cat_id_8"
    And  I click "#index-bulk-submit-wbrs"
    And  I wait for "10" seconds
    And  I should see "ENTRIES HAVE BEEN UPDATED"
    Then I click button with class "close"
    And  I wait for "1" seconds
    Then I click "#index-adjust-wlbl"
    And  I wait for "2" seconds
#    And  take a screenshot
    And  Element with class "wlbl-entry-wlbl" should have content "BL-weak"
    And  clean up wlbl and remove all wlbl entries on "imadethisurlup.com"


  @javascript
  Scenario: a user removes an entry from one WBRS list and adds it to another on the dispute show page
  #  after adding one first so we're starting with clean data
    Given a user with role "webrep user" exists and is logged in
    Given the following disputes exist:
      | id | submission_type |
      | 1  | w               |
    Given the following dispute_entries exist:
      | id | uri                |
      | 1  | imadethisurlup.com |
    And  clean up wlbl and remove all wlbl entries on "imadethisurlup.com"
    When I goto "escalations/webrep/disputes/1"
    And  I wait for "2" seconds
    Then I click "#research-tab-link"
    And  I click "#wlbl_button_1"
    And  I wait for "5" seconds
    And  I should see "Not on a list"
    And  I should see "No score"
    Then I click "#wl-weak-slider"
    And  I click "Submit Changes"
    And  I wait for "5" seconds
    Then I click button with class "close"
    And  I wait for "1" seconds
    And  I click "#wlbl_button_1"
    And  I wait for "5" seconds
    And  I should not see "Not on a list"
    And  Element with class "wlbl-entry-wlbl" should have content "WL-weak"
    # Now we're actually removing and adding
    Then I click "#wl-weak-slider"
    And  I click "#bl-weak-slider"
    And  I should see "Bogon"
    And  I should see "Cryptojacking"
    And  I should see "Phishing"
    And  I click ".wlbl_thrt_cat_id_8"
    And  I click "Submit Changes"
    And  I wait for "5" seconds
    Then I click button with class "close"
    And  I wait for "1" seconds
    And  I click "#wlbl_button_1"
    And  I wait for "5" seconds
    And  Element with class "wlbl-entry-wlbl" should have content "BL-weak"
    And  Element with class "wlbl-entry-wlbl" should not have content "WL-weak"
    And  clean up wlbl and remove all wlbl entries on "imadethisurlup.com"


  @javascript
  Scenario: a user adds multiple entries to a WBRS list from the dispute show page
    Given a user with role "webrep user" exists and is logged in
    Given the following disputes exist:
      | id | submission_type |
      | 1  | w               |
    Given the following dispute_entries exist:
      | id | uri                |
      | 1  | imadethisurlup.com |
      | 2  | thisurlisfake.com  |
    And  clean up wlbl and remove all wlbl entries on "imadethisurlup.com"
    And  clean up wlbl and remove all wlbl entries on "thisurlisfake.com"
    When I goto "escalations/webrep/disputes/1"
    And  I wait for "2" seconds
    Then I click "#research-tab-link"
    And  I check checkbox with class "dispute-entry-cb-1"
    And  I check checkbox with class "dispute-entry-cb-2"
    And  I click button "wlbl_entries_button"
    And  I wait for "5" seconds
    Then I check checkbox with class "bl-weak-checkbox"
    And  I click ".wlbl_thrt_cat_id_1"
    And  I click ".wlbl_thrt_cat_id_2"
    And  I click "Submit Changes"
    And  I wait for "5" seconds
    Then I click button with class "close"
    And  I wait for "2" seconds
    Then I click button "wlbl_entries_button"
    And  I wait for "5" seconds
    And  Element with class "wlbl-entry-id-1" should have content "BL-weak"
    And  Element with class "wlbl-entry-id-2" should have content "BL-weak"
    And  clean up wlbl and remove all wlbl entries on "imadethisurlup.com"
    And  clean up wlbl and remove all wlbl entries on "thisurlisfake.com"


  @javascript
  Scenario: a user removes multiple entries from a WBRS list on the dispute show page
  #  after adding them to one first so we start with clean api data
    Given a user with role "webrep user" exists and is logged in
    Given the following disputes exist:
      | id | submission_type |
      | 1  | w               |
    Given the following dispute_entries exist:
      | id | uri                |
      | 1  | imadethisurlup.com |
      | 2  | thisurlisfake.com  |
    And  clean up wlbl and remove all wlbl entries on "imadethisurlup.com"
    And  clean up wlbl and remove all wlbl entries on "thisurlisfake.com"
    When I goto "escalations/webrep/disputes/1"
    And  I wait for "2" seconds
    Then I click "#research-tab-link"
    And  I check checkbox with class "dispute-entry-cb-1"
    And  I check checkbox with class "dispute-entry-cb-2"
    And  I click button "wlbl_entries_button"
    And  I wait for "5" seconds
    Then I check checkbox with class "wl-weak-checkbox"
    Then I check checkbox with class "wl-med-checkbox"
    And  I click "Submit Changes"
    And  I wait for "5" seconds
    Then I click button with class "close"
    And  I wait for "2" seconds
    Then I click button "wlbl_entries_button"
    And  I wait for "5" seconds
    And  Element with class "wlbl-entry-id-1" should have content "WL-weak, WL-med"
    And  Element with class "wlbl-entry-id-2" should have content "WL-weak, WL-med"
    And  I choose "wlbl-remove"
    Then I check checkbox with class "wl-med-checkbox"
    And  I click "Submit Changes"
    And  I wait for "5" seconds
    Then I click button with class "close"
    And  I wait for "2" seconds
    Then I click button "wlbl_entries_button"
    And  I wait for "5" seconds
    And  Element with class "wlbl-entry-id-1" should have content "WL-weak"
    And  Element with class "wlbl-entry-id-1" should not have content "WL-med"
    And  Element with class "wlbl-entry-id-2" should have content "WL-weak"
    And  Element with class "wlbl-entry-id-2" should not have content "WL-med"
    And  clean up wlbl and remove all wlbl entries on "imadethisurlup.com"
    And  clean up wlbl and remove all wlbl entries on "thisurlisfake.com"






  @javascript
  Scenario: a user tries to export selected dispute entries on the Research tab
    Given pending
    # Note that selenium doesn't support viewing response headers as is required by this test, maybe just get rid of it
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id |
      | 1  |
    When I goto "/escalations/webrep/disputes/1"
    And I click "#research-tab-link"
    And I click ".dispute_check_box"
    And I click "Export Selected to CSV"
    Then I wait for "3" seconds
    Then I should receive a file of type "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

  @javascript
  Scenario: A user creates a new resolution message template
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id   |
      | 5370 |
    And I goto "/escalations/webrep/disputes/5370"
    And I click ".mng-resolution-message-templates-button"
    And I click "#create-resolution-message-template"
    And I fill in "new-resolution-message-template-name" with "Testimony"
    And I fill in "new-resolution-message-template-desc" with "Apples and Carrots"
    And I fill in "new-resolution-message-template-body" with "Teenage Mutant Ninja Turtles"
    When I click "#save-resolution-message-template"
    And I wait for "3" seconds
    Then I should see "RESOLUTION MESSAGE TEMPLATE CREATED."

  @javascript
  Scenario: A user selects a resolution message template and updates it
    Given a user with role "webrep user" exists and is logged in
    And a resolution message template exists
    And the following disputes exist and have entries:
      | id   |
      | 5370 |
    And I goto "/escalations/webrep/disputes/5370"
    And I click ".mng-resolution-message-templates-button"
    Then I should see "Templar"
    Then I should see "Axe"
    Given I click ".edit-resolution-message-template"
    Then I wait for "3" seconds
    Then I should see content "This is a test." within "#edit-resolution-message-template-body"
    Given I fill in "edit-resolution-message-template-body" with "ABC"
    When I click "#edit-resolution-message-template"
    And I wait for "3" seconds
    Then I should see "RESOLUTION MESSAGE TEMPLATE UPDATED."

  @javascript
  Scenario: A user deletes a resolution message template
    Given a user with role "webrep user" exists and is logged in
    And a resolution message template exists
    And the following disputes exist and have entries:
      | id   |
      | 5370 |
    And I goto "/escalations/webrep/disputes/5370"
    And I click ".mng-resolution-message-templates-button"
    When I click ".delete-resolution-message-template"
    And I click ".confirm"
    And I wait for "3" seconds
    Then I should see "RESOLUTION MESSAGE TEMPLATE DELETED."

  @javascript
  Scenario: A user selects a resolution message template
    Given a user with role "webrep user" exists and is logged in
    And a resolution message template exists
    And the following disputes exist and have entries:
      | id   |
      | 5370 |
    And I goto "/escalations/webrep/disputes/5370"
    And I click "#show-edit-ticket-status-button"
    And I click "#NEW"
    When I select "Templar" from "select-new-resolution-message-template-status"
    And I wait for "3" seconds
    Then I should see content "This is a test." within ".ticket-status-comment"

  @javascript
  Scenario: A user creates a new resolution message template
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id   |
      | 5370 |
    And I goto "/escalations/webrep/disputes/5370"
    And I click ".mng-resolution-message-templates-button"
    And I click "#create-resolution-message-template"
    When I click "#save-resolution-message-template"
    And I wait for "3" seconds
    Then I should see "THERE WAS AN ERROR CREATING THE RESOLUTION MESSAGE TEMPLATE."
    Then I should see "Name can't be blank and Body can't be blank"

  Scenario: A user creates a new named search for disputes
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |  id  |  status  | user_id |
      | 5370 | ASSIGNED |    1    |
    When I goto "/escalations/webrep/disputes"
    And I click "#advanced-search-button"
    And I fill in "search_name" with "Lab"
    And I click "#submit-advanced-search"
    And I click "#filter-cases"
    Then I should see content "Lab" within "#saved-searches-wrapper"

  @javascript
  Scenario: A user uses a new named search for disputes
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id |     status      |
      |  1 |       NEW       |
      |  2 |       NEW       |
      |  3 | RESOLVED_CLOSED |
    And a named search with the name, "Cucumber" exists
    And a named search criteria exists with field_name: "status" and value: "NEW"
    When I goto "/escalations/webrep/disputes?f=closed"
    And  I wait for "3" seconds
    And  I should see content "RESOLVED_CLOSED" within ".dispute_status"
    Then I should not see "0000000001"
    And  I should not see content "NEW" within ".dispute_status"
    And  I should not see "0000000002"
    When I click "#filter-cases"
    And  I click ".saved-search"
    And  I wait for "3" seconds
    Then I should see "0000000001"
    And  I should see content "NEW" within first element of class ".dispute_status"
    And  I should see "0000000002"

  @javascript
  Scenario: A user creates a new named search for disputes
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |  id  |  status  | user_id |
      | 5370 | ASSIGNED |    1    |
    When I goto "/escalations/webrep/disputes?f=open"
    And  I wait for "3" seconds
    And I click "#advanced-search-button"
    And I fill in "search_name" with "Cucumber"
    And I click "#submit-advanced-search"
    And I click "#filter-cases"
    Then I should see content "Cucumber" within "#saved-searches-wrapper"

  @javascript
  Scenario: A user creates a duplicate named search for disputes
    Given a user with role "webrep user" exists and is logged in
    And a named search with the name, "Cucumber" exists
    And a named search criteria exists with field_name: "status" and value: "NEW"
    And the following disputes exist and have entries:
      |  id  |  status  | user_id |
      | 5370 | ASSIGNED |    1    |
    When I goto "/escalations/webrep/disputes?f=open"
    And  I wait for "3" seconds
    And I click "#advanced-search-button"
    And I fill in "search_name" with "Cucumber"
    And I click "#submit-advanced-search"
    And I click "#filter-cases"
    Then I should see content "Cucumber" within "#saved-searches-wrapper"
    And There is only one element of class, "saved-search"

  @javascript
  Scenario: A user creates a new named search for disputes and stays on the page (tests to make sure multiple named search criteria are not created)
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |  id  |  status  | user_id |
      | 5370 | ASSIGNED |    1    |
    When I goto "/escalations/webrep/disputes?f=open"
    And  I wait for "3" seconds
    And I click "#advanced-search-button"
    And I fill in "search_name" with "Cucumber"
    And I click "#submit-advanced-search"
    And I click "#filter-cases"
    Then I should see content "Cucumber" within "#saved-searches-wrapper"

  @javascript
  Scenario: A user visits the Dashboard page and sees correct ticket counts
    Given a user with id "1" has a role "webrep user" and is logged in
    And the following disputes exist and have entries:
      | id   | status   | user_id |
      | 5370 | ASSIGNED | 1       |
    And the following disputes exist and have entries:
      | id   | status   | user_id |
      | 5371 | ASSIGNED | 1       |
    And the following disputes exist and have entries:
      | id   | status   | user_id |
      | 5372 | ASSIGNED | 1       |
    And the following disputes exist and have entries:
      | id   | status      | user_id |
      | 5373 | RESEARCHING | 1       |
    And the following disputes exist and have entries:
      | id   | status      | user_id |
      | 5374 | RESEARCHING | 1       |
    And the following disputes exist and have entries:
      | id   | status          | user_id |
      | 5375 | RESOLVED_CLOSED | 1       |
    And the following disputes exist and have entries:
      | id   | status          | user_id |
      | 5376 | RESOLVED_CLOSED | 1       |
    And the following disputes exist and have entries:
      | id   | status          | user_id |
      | 5377 | RESOLVED_CLOSED | 1       |
    And the following disputes exist and have entries:
      | id   | status          | user_id |
      | 5378 | RESOLVED_CLOSED | 1       |
    When I goto "/escalations/webrep/dashboard"
    And I click "#ticket-view-shortcut"
    Then I should see content "3" within "#open_single_ticket_count"
    Then I should see content "4" within "#closed_single_ticket_count"

  @javascript
  Scenario: A user visits the Dashboard page and sees correct ticket counts for their team
    Given a user with id "1" has a role "webrep user" and is logged in
    And I add a test user to current user's team
    And the following disputes exist and have entries:
      | id   | status   | user_id |
      | 5370 | ASSIGNED | 2       |
    And the following disputes exist and have entries:
      | id   | status   | user_id |
      | 5371 | ASSIGNED | 1       |
    And the following disputes exist and have entries:
      | id   | status   | user_id |
      | 5372 | ASSIGNED | 1       |
    And the following disputes exist and have entries:
      | id   | status      | user_id |
      | 5373 | RESEARCHING | 2       |
    And the following disputes exist and have entries:
      | id   | status      | user_id |
      | 5374 | RESEARCHING | 1       |
    And the following disputes exist and have entries:
      | id   | status          | user_id |
      | 5375 | RESOLVED_CLOSED | 1       |
    And the following disputes exist and have entries:
      | id   | status          | user_id |
      | 5376 | RESOLVED_CLOSED | 1       |
    And the following disputes exist and have entries:
      | id   | status          | user_id |
      | 5377 | RESOLVED_CLOSED | 1       |
    And the following disputes exist and have entries:
      | id   | status          | user_id |
      | 5378 | RESOLVED_CLOSED | 2       |
    When I goto "/escalations/webrep/dashboard"
    And I click "#ticket-view-shortcut"
    Then I should see content "2" within "#open_single_ticket_count"
    Then I should see content "3" within "#closed_single_ticket_count"
    Then I click "My Team Tickets"
    Then I should see content "3" within "#open_multi_ticket_count"
    Then I should see content "4" within "#closed_multi_ticket_count"

  @javascript
  Scenario: A user tries to update a dispute
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id   |
      | 5370 |
    When I goto "/escalations/webrep/disputes/5370"
    And I click "#show-edit-ticket-status-button"
    And I click "#ESCALATED"
    And I click ".primary"
    Then I should see content "Escalated" within "#show-edit-ticket-status-button"
    And I click "#show-edit-ticket-status-button"
    And I click "#RESEARCHING"
    And I click ".primary"
    Then I should see content "RESEARCHING" within "#show-edit-ticket-status-button"
    When I click ".edit-button"
    And I fill in "dispute-customer-name-input" with "John Smith"
    And I fill in "dispute-customer-email-input" with "jsmith@cisco.com"
    And I select "P5" from "dispute-priority-select"
    And I click "#save-dispute-button"
    And I wait for "5" seconds
    And I click "#top_bar_toggle"
    Then I should see content "John Smith" within "#dispute-customer-name"
    And I should see content "jsmith@cisco.com" within "#dispute-customer-email"
    And Dispute entry should have a status of, "P5"

  @javascript
  Scenario: A user tries add a new dispute entry (ad hoc)
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
      | id   |
      | 5370 |
    And I goto "/escalations/webrep/disputes/5370"
    Then I click link "Research"
    When I click "#add-entries-button"
    And I fill in "add_dispute_entry" with "cisco.com"
    And I click "#button_add_dispute_entry"
    And I wait for "15" seconds
    Then I should see content "cisco.com" within ".entry-data-content"
    And I should see content "WL-med" within ".entry-data-wlbl"
    And I should see content "BL-heavy" within ".entry-data-wlbl"

  @javascript
  Scenario: Loading cogs appear when landing on a page and disappear after it is done loading
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
      | id   |
      | 5370 |
    And I create WebRep Entries Per Page UserPreference
    And I create WebRep Sort Order UserPreference
    And I create WebRep Current Page UserPreference
    When I goto "/escalations/webrep/disputes/"
    Then I should see "Loading data..."
    And I wait for "1" seconds
    Then I should not see "Loading data..."