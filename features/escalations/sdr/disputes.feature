Feature: Disputes
  In order to interact with disputes
  as a user
  I will provide ways to interact with disputes

  @javascript
  Scenario: A user cannot create a duplicate url Dispute
    Then pending
    # waiting on making a new SDR Dispute functionality
    Given a user with role "webrep user" exists and is logged in
    Given the following SDR disputes exist:
      | id |
      | 1  |
    Given a dispute exists and is related to disputes with ID, "1":
    When I go to "/escalations/sdr/disputes"
    And I wait for "2" seconds
    Then I click "new-dispute"
    And I fill in "assignee" with "nherbert"
    When I click "submit"
    Then I should see "Unable to create the following duplicate dispute entries: talosintelligence.com"

  @javascript
  Scenario: A user can create new disputes with urls found through lookup detail
    Then pending
    # waiting on making a new SDR Dispute functionality and the research tab
    Given a user with role "webrep user" exists and is logged in
    And vrtincoming exists
    And bugzilla rest api always saves
    And Dispute Analyst customer exists
    When I go to "/escalations/sdr/research#lookup-detail"
    And I fill in "search_uri" with "ough.com"
    Then I click "submit-button rep-research"
    And I wait for "60" seconds
    Then I should see "Entry Search Results for"
    Then I click "#select-all-entries"
    Then I click "add-to-ticket-button"
    When I click ".submit_new_dispute"
    And I wait for "60" seconds
    Then I should see "ALL ENTRIES WERE SUCCESSFULLY CREATED."

  @javascript
  Scenario: The index will not break with a mostly empty record
    Then pending
    # waiting on the index page
    Given a user with role "webrep user" exists and is logged in
    Given an empty dispute exists
    When I go to "/escalations/sdr/disputes"
    Then I should see content "0000000001" within "#disputes-index"

  @javascript
  Scenario: the last submitted field returns data
    Then pending
    # waiting on research tab
    Given a user with role "admin" exists and is logged in
    And the following SDR disputes exist:
      | id |
      | 1  |
      | 2  |
    Then I go to "/escalations/sdr/disputes/1"
    Then I click link "Research"
    Then Expect date in element "#last-submitted" to equal today's date

  @javascript
  Scenario: a user can see data in the Submitter Type column
    Then pending
    # waiting on sdr index
    Given a user with role "webrep user" exists and is logged in
    And the following SDR disputes exist:
      | id | submitter_type |
      | 1  | CUSTOMER       |
    Then I goto "escalations/sdr/"
    Then I wait for "2" seconds
    When I click "#table-show-columns-button"
    And I click "#submitter-type-checkbox"
    Then I should see table header with id "submitter-type"
    Then I should see "CUSTOMER"

  @javascript
  Scenario: a user takes a dispute and status is updated to assigned
    Then pending
    #waiting on index
    Given a user with role "webrep user" exists with cvs_username, "Cucumber", exists and is logged in
    Given the following users exist
      | id | cvs_username |
      | 3  | vrtincom     |
    And the following SDR disputes exist:
      | id | user_id |
      | 2  | 3       |
    When I goto "escalations/sdr/disputes"
    And I click ".take-dispute-2"
    Then I see "ASSIGNED" in element "#status_2"
    Then I should see user, "Cucumber", in element "#owner_2"

  @javascript
  Scenario: a user takes a dispute, returns a dispute, and takes the dispute again
    Then pending
    # waiting on index
    Given a user with role "webrep user" exists with cvs_username, "Cucumber", exists and is logged in
    Given the following users exist
      | id | cvs_username |
      | 3  | vrtincom     |
    And the following sdr disputes exist:
      | id | user_id |
      | 2  | 3       |
    When I goto "escalations/sdr/disputes"
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
    Then pending
    # waiting on research tab
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id |
      | 1  |
    When I goto "escalations/sdr/disputes/1/"
    And I click "#research-tab-link"
    And I click ".inline-edit-entry-button"
    And I click "#entry_status_button_1"
    And I click "#RE-OPENED"
    And I click ".save-all-changes"
    Then I wait for "3" seconds
    Then I should see "RE-OPENED"

  @javascript
  Scenario: when the user encounters a situation in which no results exists (therefore none returned), an error modal should display
    Then pending
    # waiting on index page
    Given a user with role "webrep user" exists and is logged in
    When I goto "escalations/sdr/disputes"
    Then I should see "NO TICKETS MATCHING FILTER OR SEARCH."

  @javascript
  Scenario: a user uses advanced search filter (Submitted Older/Modified Older) and exports to csv
    Then pending
    # waiting on index page
    # Note that selenium doesn't support viewing response headers as is required by this test, maybe just get rid of it
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id |
      | 1  |
    When I goto "escalations/sdr/disputes?f=open"
    And I click "#advanced-search-button"
    And I click "#add-search-items-button"
    And I click "#submitted-older-cb"
    And I click "#modified-older-cb"
    Then I click "#cancel-add-criteria"
    And I click "#submit-advanced-search"
    Then I click ".export-all-btn"
    # Thomas Walpole says that selenium driver does not provide access to response headers
    # https://stackoverflow.com/questions/55584140/capybara-fails-with-notsupportedbydrivererror
    # Then I wait for "3" seconds
    # Then I should receive a file of type "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"'

  @javascript
  Scenario: a user adds and selects columns from the Column drop-down
    Then pending
    # waiting on index page
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id |
      | 1  |
    When I goto "escalations/sdr/disputes?f=open"
    And I wait for "3" seconds
    And I click "#table-show-columns-button"
    And I click "#case-id-checkbox"
    And I click "#status-checkbox"
    And I click "#submitter-type-checkbox"
    And I click "#submitter-org-checkbox"
    And I click "#submitter-domain-checkbox"
    And I click "#contact-name-checkbox"
    And I click "#contact-email-checkbox"
    When I goto "escalations/sdr/disputes?f=open"
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
    Then pending
    # waiting on index page
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id | submission_type |
      | 1  | w               |
    When I goto "escalations/sdr/disputes?f=all"
    And I click "#table-show-columns-button"
    And I click "#contact-name-checkbox"
    And I click "#table-show-columns-button"
    And I click "#advanced-search-button"
    And I click "#add-search-items-button"
    And I click "#name-cb"
    Then I fill in "name-input" with "Bob Jones"
    Then I click "#cancel-add-criteria"
    Then I click "#submit-advanced-search"
    And I wait for "5" seconds
    And I click "#advanced-search-button"
    Then I wait for "5" seconds
    Then I should see "talosintelligence.com"
    Then I should see "0000000001"
    Then I should see "Bob Jones"

  @javascript
  Scenario: a users uses advanced search with 'Contact Email' as a search criteria
    Then pending
    # waiting on index page
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id | submission_type |
      | 1  | w               |
    When I goto "escalations/sdr/disputes?f=all"
    And I click "#table-show-columns-button"
    And I click "#contact-email-checkbox"
    And I click "#table-show-columns-button"
    And I click "#advanced-search-button"
    And I click "#add-search-items-button"
    And I click "#email-cb"
    Then I click "#cancel-add-criteria"
    Then I fill in "email-input" with "bob@bob.com"
    Then I click "#submit-advanced-search"
    And I wait for "3" seconds
    And I click "#advanced-search-button"
    Then I wait for "5" seconds
    Then I should see "talosintelligence.com"
    Then I should see "0000000001"
    Then I should see "bob@bob.com"

  @javascript
  Scenario: a users uses advanced search with 'Company' as a search criteria
    Then pending
    # waiting on index page
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id | submission_type |
      | 1  | w               |
    When I goto "escalations/sdr/disputes?f=all"
    And I click "#table-show-columns-button"
    And I click "#submitter-org-checkbox"
    And I click "#table-show-columns-button"
    And I click "#advanced-search-button"
    And I click "#add-search-items-button"
    And I click "#company-cb"
    Then I fill in "company-input" with "Bobs Burgers"
    Then I click "#cancel-add-criteria"
    Then I click "#submit-advanced-search"
    And I wait for "3" seconds
    Then I should see "talosintelligence.com"
    Then I should see "0000000001"
    Then I should see "Bobs Burgers"

  @javascript
  Scenario: a user uses advanced search with 'Platform' as a search criteria
    Then pending
    # waiting on index page
    Given a user with role "webrep user" exists and is logged in
    And platforms with all traits exist
    Given the following disputes exist:
      | id | submission_type | platform_id |
      | 1  |        w        |  1          |
      | 2  |        w        |             |
      | 3  |        e        |  3          |
    Given the following dispute_entries exist:
      | id | ip_address   | dispute_id | platform_id |
      | 1  | 123.63.22.24 |  1         |             |
      | 2  | 724.35.87.12 |  2         | 2           |
      | 3  | 876.25.65.34 |  3         |             |
    When I goto "escalations/sdr/disputes?f=all"
    And I click "#advanced-search-button"
    And I click "#add-search-items-button"
    And I click "#platform-cb"
    And I wait for "5" seconds
    And I fill in selectized of element "#platform-input" with "['1', '2']"
    Then I click "#cancel-add-criteria"
    Then I click "#submit-advanced-search"
    Then I should see "0000000001"
    And I should see "0000000002"
    And I should not see "0000000003"


  @javascript
  Scenario: a user wants to do an advanced search and ensure those previous values are cleared on subsequent search
    Then pending
    # waiting on index page
    Given a user with role "webrep user" exists and is logged in
    Given the following disputes exist:
      | id | submission_type | status    |
      | 1  | w               | ESCALATED |
      | 2  | e               | PENDING   |
    And the following dispute_entries exist:
      | dispute_id   | uri             | entry_type |
      | 1            | whatever.com    | URI/DOMAIN |
      | 2            | iamatest.com    | URI/DOMAIN |
    When I goto "escalations/sdr/disputes?f=all"
    And I should see "All Tickets"
    And I click "#advanced-search-button"
    And I should see "Advanced Search"
    And I fill in "status-input" with "ESCALATED"
    And I should see content "ESCALATED" within "#status-input"
    Then I click "#submit-advanced-search"
    And I wait for "3" seconds
    Then I should see "0000000001"
    Then I should see "ESCALATED"
    Then I should not see "0000000002"
    Then I should not see "PENDING"
    And I click "#advanced-search-button"
    And I click "#remove-criteria-status"
    And I click "#add-search-items-button"
    And I click "#status-cb"
    And I click "#cancel-add-criteria"
    And I should not see content "ESCALATED" within "#status-input"
    And I fill in "dispute-input" with "iamatest.com"
    And I should see content "iamatest.com" within "#dispute-input"
    Then I click "#submit-advanced-search"
    And I wait for "3" seconds
    Then I should see "0000000002"
    Then I should see "iamatest.com"
    Then I should not see "ESCALATED"


  @javascript
  Scenario: a user tries to export selected dispute entries
    Then pending
    # waiting on index page
    # Note that selenium doesn't support viewing response headers as is required by this test, maybe just get rid of it
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id | submission_type |
      | 1  | w               |
    When I goto "escalations/sdr/disputes?f=open"
    And I click ".dispute_check_box"
    And I click ".export-selected-btn"
    # Thomas Walpole says that selenium driver does not provide access to response headers
    # https://stackoverflow.com/questions/55584140/capybara-fails-with-notsupportedbydrivererror
    # Then I wait for "3" seconds
    # Then I should receive a file of type "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

  @javascript
  Scenario: a user wants to do an advanced search and ensure those previous values are cleared on subsequent search
    Then pending
    # waiting on index page
    Given a user with role "webrep user" exists and is logged in
    Given the following disputes exist:
      | id       | submission_type | status    |
      | 1        | w               | ESCALATED |
      | 2000002  | e               | PENDING   |
    And the following dispute_entries exist:
      | dispute_id   | ip_address     | entry_type |
      | 1            | 162.219.31.5   | IP         |
      | 2000002      | 162.219.31.5   | IP         |
    When I goto "escalations/sdr/disputes/1"
    Then I click "#research-tab-link"
    Then I click button with class "show_references"
    And  I click "2000002"
    And  I wait for "5" seconds
    And  I should see "0002000002"
    And I should see "PENDING"


  ### WBRS WL/BL Dropdown

  @javascript
  Scenario: a user wants to view the current WBRS lists and score for an entry from the index page
    Then pending
    # waiting on index page
    Given a user with role "webrep user" exists and is logged in
    Given the following disputes exist:
      | id | submission_type |
      | 1  | w               |
    Given the following dispute_entries exist:
      | id | uri                   |
      | 1  | imadethisurlup.com    |
    # Adding this step below to ensure the api data is clear
    And  clean up wlbl and remove all wlbl entries on "imadethisurlup.com"
    When I goto "escalations/sdr/disputes?f=open"
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
    Then pending
    # waiting on index page
    Given a user with role "webrep user" exists and is logged in
    Given the following disputes exist:
      | id | submission_type |
      | 1  | w               |
    Given the following dispute_entries exist:
      | id | uri                |
      | 1  | imadethisurlup.com |
    When I goto "escalations/sdr/disputes?f=open"
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
    Then pending
    # waiting on index page
  #  after adding it so we're starting with clean data from the api
    Given a user with role "webrep user" exists and is logged in
    Given the following disputes exist:
      | id | submission_type |
      | 1  | w               |
    Given the following dispute_entries exist:
      | id | uri                |
      | 1  | imadethisurlup.com |
    When I goto "escalations/sdr/disputes?f=open"
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
    Then pending
    # waiting on index page
    Given a user with role "webrep user" exists and is logged in
    Given the following disputes exist:
      | id | submission_type |
      | 1  | w               |
    Given the following dispute_entries exist:
      | id | uri                |
      | 1  | imadethisurlup.com |
    When I goto "escalations/sdr/disputes?f=open"
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
    Then pending
    # waiting on research tab
  #  after adding one first so we're starting with clean data
    Given a user with role "webrep user" exists and is logged in
    Given the following disputes exist:
      | id | submission_type |
      | 1  | w               |
    Given the following dispute_entries exist:
      | id | uri                |
      | 1  | imadethisurlup.com |
    And  clean up wlbl and remove all wlbl entries on "imadethisurlup.com"
    When I goto "escalations/sdr/disputes/1"
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
    Then pending
    # waiting on research tab
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
    When I goto "escalations/sdr/disputes/1"
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
    Then pending
    # waiting on reseearch tab
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
    When I goto "escalations/sdr/disputes/1"
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
    Then pending
    # waiting on research tab
    # Note that selenium doesn't support viewing response headers as is required by this test, maybe just get rid of it
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id |
      | 1  |
    When I goto "/escalations/sdr/disputes/1"
    And I click "#research-tab-link"
    And I click ".dispute_check_box"
    And I click "Export Selected to CSV"
    # Thomas Walpole says that selenium driver does not provide access to response headers
    # https://stackoverflow.com/questions/55584140/capybara-fails-with-notsupportedbydrivererror
    #Then I wait for "3" seconds
    #Then I should receive a file of type "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

  Scenario: A user creates a new named search for disputes
    Then pending
    #waiting for index
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |  id  |  status  | user_id |
      | 5370 | ASSIGNED |    1    |
    When I goto "/escalations/sdr/disputes"
    And I click "#advanced-search-button"
    And I fill in "search_name" with "Lab"
    And I click "#submit-advanced-search"
    And I click "#filter-cases"
    Then I should see content "Lab" within "#saved-searches-wrapper"

  @javascript
  Scenario: A user uses a new named search for disputes
    Then pending
    #waiting for index
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id |     status      |
      |  1 |       NEW       |
      |  2 |       NEW       |
      |  3 | RESOLVED_CLOSED |
    And a named search with the name, "Cucumber" exists
    And a named search criteria exists with field_name: "status" and value: "NEW"
    When I goto "/escalations/sdr/disputes?f=closed"
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
    Then pending
    #waiting for index
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |  id  |  status  | user_id |
      | 5370 | ASSIGNED |    1    |
    When I goto "/escalations/sdr/disputes?f=open"
    And  I wait for "3" seconds
    And I click "#advanced-search-button"
    And I fill in "search_name" with "Cucumber"
    And I click "#submit-advanced-search"
    And I click "#filter-cases"
    Then I should see content "Cucumber" within "#saved-searches-wrapper"

  @javascript
  Scenario: A user creates a duplicate named search for disputes
    Then pending
    #waiting for index
    Given a user with role "webrep user" exists and is logged in
    And a named search with the name, "Cucumber" exists
    And a named search criteria exists with field_name: "status" and value: "NEW"
    And the following disputes exist and have entries:
      |  id  |  status  | user_id |
      | 5370 | ASSIGNED |    1    |
    When I goto "/escalations/sdr/disputes?f=open"
    And  I wait for "3" seconds
    And I click "#advanced-search-button"
    And I fill in "search_name" with "Cucumber"
    And I click "#submit-advanced-search"
    And I click "#filter-cases"
    Then I should see content "Cucumber" within "#saved-searches-wrapper"
    And There is only one element of class, "saved-search"

  @javascript
  Scenario: A user creates a new named search for disputes and stays on the page (tests to make sure multiple named search criteria are not created)
    Then pending
    #waiting for index
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |  id  |  status  | user_id |
      | 5370 | ASSIGNED |    1    |
    When I goto "/escalations/sdr/disputes?f=open"
    And  I wait for "3" seconds
    And I click "#advanced-search-button"
    And I fill in "search_name" with "Cucumber"
    And I click "#submit-advanced-search"
    And I click "#filter-cases"
    Then I should see content "Cucumber" within "#saved-searches-wrapper"

  @javascript
  Scenario: A user visits the Dashboard page and sees correct ticket counts
    Then pending
    #waiting for index
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
    When I goto "/escalations/sdr/dashboard"
    And I click "#ticket-view-shortcut"
    Then I should see content "3" within "#open_single_ticket_count"
    Then I should see content "4" within "#closed_single_ticket_count"

  @javascript
  Scenario: A user visits the Dashboard page and sees correct ticket counts for their team
    Then pending
    #waiting for index
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
    When I goto "/escalations/sdr/dashboard"
    And I click "#ticket-view-shortcut"
    Then I should see content "2" within "#open_single_ticket_count"
    Then I should see content "3" within "#closed_single_ticket_count"
    Then I click "My Team Tickets"
    Then I should see content "3" within "#open_multi_ticket_count"
    Then I should see content "4" within "#closed_multi_ticket_count"

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
    #waiting on priority to be added to SDR
   #And I select "P5" from "dispute-priority-select"
   #And I click "#save-dispute-button"
   #And I wait for "5" seconds
   #And I click "#top_bar_toggle"
   #Then I should see content "John Smith" within "#dispute-customer-name"
   #And I should see content "jsmith@cisco.com" within "#dispute-customer-email"
   #And Dispute entry should have a status of, "P5"

  @javascript
  Scenario: Loading cogs appear when landing on a page and disappear after it is done loading
    Then pending
    # waiting on index page
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
      | id   |
      | 5370 |
    And I create sdr Entries Per Page UserPreference
    And I create sdr Sort Order UserPreference
    And I create sdr Current Page UserPreference
    When I goto "/escalations/sdr/disputes/"
    Then I should see "Loading data..."
    And I wait for "1" seconds
    Then I should not see "Loading data..."

  @javascript
  Scenario: left nav links should apply filter if the filter was set before
    Then pending
    # waiting on index page
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |  id       |  status         | user_id |
      | 000001    | ASSIGNED        |    1    |
      | 000002    | RESOLVED_CLOSED |    1    |
    When I goto "/escalations/sdr/disputes?f=open"
    Then I should see "000001"
    And I should not see "000002"
    When I click "#nav-trigger-label"
    And I click "Escalations"
    And I click "#rep-icon-link"
    Then I should see "000001"
    And I should not see "000002"
    When I click "#nav-trigger-label"
    And I click "Escalations"
    And I click "#rep-link"
    Then I should see "000001"
    And I should not see "000002"

  @javascript
  Scenario: top nav links should apply filter if the filter was set before
    Then pending
    # waiting on index page
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |  id       |  status         | user_id |
      | 000001    | ASSIGNED        |    1    |
      | 000002    | RESOLVED_CLOSED |    1    |
    When I goto "/escalations/sdr/disputes?f=open"
    Then I should see "000001"
    And I should not see "000002"
    When I click "#queue"
    Then I should see "000001"
    And I should not see "000002"
