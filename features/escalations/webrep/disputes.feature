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
  Scenario: A user can create new disputes with urls found through lookup detail
    Given a user with role "webrep user" exists and is logged in
    And vrtincoming exists
    And bugzilla rest api always saves
    And Dispute Analyst customer exists
    When I go to "/escalations/webrep/research#lookup-detail"
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
    Given a user with role "webrep user" exists and is logged in
    Given an empty dispute exists
    When I go to "/escalations/webrep/disputes"
    Then I should see content "0000000001" within "#disputes-index"

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
  Scenario: a user picks a resolution on the index page and the comment is pre-populated
    Given a user with role "webrep user" exists and is logged in
    And a guest company exists
    And the following customers exist:
      | id | company_id |   name   | email                 |
      | 3  |      1     |  guest   | guest@guest.com       |
      | 4  |      2     | customer | customer@customer.com |
    Given the following disputes exist and have entries:
      | id | submission_type |   submitter_type   | customer_id |
      | 1  |        w        |    CUSTOMER        |     4       |
      | 2  |        e        |    CUSTOMER        |     4       |
      | 3  |        w        |    NON-CUSTOMER    |     3       |
    When I goto "escalations/webrep/disputes/"
    Then I check "cbox0000000001"
    And I click "#index_ticket_status"
    And I click "#RESOLVED_CLOSED"
    #Should show full messages for customer submissions
    And I click "#FIXED_FP"
    Then I should see "Talos has concluded that the submission is safe to access at this time; the submission’s reputation has been improved. This update will be publicly visible in the next 24 hours. If your device or endpoint client is not reflecting this disposition, please open a TAC case."
    When I click "#FIXED_FN"
    Then I should see "Talos has concluded that the submission is unsafe to access at this time due to malicious activity; the submission’s reputation has been decreased. This update will be publicly visible in the next 24 hours. If your device or endpoint client is not reflecting this disposition, please open a TAC case."
    When I click "#UNCHANGED"
    Then I should see "Talos has not found sufficient evidence to modify the current reputation of the submission; we cannot change the submission’s reputation because it can negatively affect our customers. However, a customer has the option of locally changing a submission’s reputation, if they understand the risks in doing so. Please open a TAC case and provide additional details if you need further assistance."
    Then I uncheck "cbox0000000001"
    Then I check "cbox0000000002"
    And I click "#index_ticket_status"
    And I click "#RESOLVED_CLOSED"
    #Should not pre-populate for email type submission
    And I click "#FIXED_FP"
    Then I should not see "Talos has concluded that the submission is safe to access at this time; the submission’s reputation has been improved. This update will be publicly visible in the next 24 hours. If your device or endpoint client is not reflecting this disposition, please open a TAC case."
    When I click "#FIXED_FN"
    Then I should not see "Talos has concluded that the submission is unsafe to access at this time due to malicious activity; the submission’s reputation has been decreased. This update will be publicly visible in the next 24 hours. If your device or endpoint client is not reflecting this disposition, please open a TAC case."
    When I click "#UNCHANGED"
    Then I should not see "Talos has not found sufficient evidence to modify the current reputation of the submission; we cannot change the submission’s reputation because it can negatively affect our customers. However, a customer has the option of locally changing a submission’s reputation, if they understand the risks in doing so. Please open a TAC case and provide additional details if you need further assistance."
    Then I uncheck "cbox0000000002"
    Then I check "cbox0000000003"
    And I click "#index_ticket_status"
    And I click "#RESOLVED_CLOSED"
    #Messages change for guest submissions
    And I click "#FIXED_FP"
    Then I should see "Talos has concluded that the submission is safe to access at this time; the submission’s reputation has been improved. This update will be publicly visible in the next 24 hours."
    When I click "#FIXED_FN"
    Then I should see "Talos has concluded that the submission is unsafe to access at this time due to malicious activity; the submission’s reputation has been decreased. This update will be publicly visible in the next 24 hours."
    When I click "#UNCHANGED"
    Then I should see "Talos has not found sufficient evidence to modify the current reputation of the submission; we cannot change the submission’s reputation because it can negatively affect our customers. However, a customer has the option of locally changing a submission’s reputation, if they understand the risks in doing so."
    Then I check "cbox0000000002"
    And I click "#index_ticket_status"
    And I click "#RESOLVED_CLOSED"
    #Should not pre-populate for email type submission
    And I click "#FIXED_FP"
    Then I should not see "Talos has concluded that the submission is safe to access at this time; the submission’s reputation has been improved. This update will be publicly visible in the next 24 hours. If your device or endpoint client is not reflecting this disposition, please open a TAC case."
    When I click "#FIXED_FN"
    Then I should not see "Talos has concluded that the submission is unsafe to access at this time due to malicious activity; the submission’s reputation has been decreased. This update will be publicly visible in the next 24 hours. If your device or endpoint client is not reflecting this disposition, please open a TAC case."
    When I click "#UNCHANGED"
    Then I should not see "Talos has not found sufficient evidence to modify the current reputation of the submission; we cannot change the submission’s reputation because it can negatively affect our customers. However, a customer has the option of locally changing a submission’s reputation, if they understand the risks in doing so. Please open a TAC case and provide additional details if you need further assistance."

  @javascript
  Scenario: a user picks a resolution for an entry on the index page and the comment is pre-populated
    Given a user with role "webrep user" exists and is logged in
    And a guest company exists
    And the following customers exist:
      | id | company_id |   name   | email                 |
      | 3  |      1     |  guest   | guest@guest.com       |
      | 4  |      2     | customer | customer@customer.com |
    Given the following disputes exist and have entries:
      | id | submission_type |   submitter_type   | customer_id |
      | 1  |        w        |    CUSTOMER        |     4       |
      | 2  |        e        |    CUSTOMER        |     4       |
      | 3  |        w        |    NON-CUSTOMER    |     3       |
    When I goto "escalations/webrep/disputes/"
    And I click "#expand-all-index-rows"
    Then I check checkbox with class "dispute-entry-checkbox_1"
    And I click "#index-entry-status-button"
    And I click "#ENTRY_RESOLVED_CLOSED"
    #Should show full messages for customer submissions
    And I click "#ENTRY_FIXED_FP"
    Then I should see "Talos has concluded that the submission is safe to access at this time; the submission’s reputation has been improved. This update will be publicly visible in the next 24 hours. If your device or endpoint client is not reflecting this disposition, please open a TAC case."
    When I click "#ENTRY_FIXED_FN"
    Then I should see "Talos has concluded that the submission is unsafe to access at this time due to malicious activity; the submission’s reputation has been decreased. This update will be publicly visible in the next 24 hours. If your device or endpoint client is not reflecting this disposition, please open a TAC case."
    When I click "#ENTRY_UNCHANGED"
    Then I should see "Talos has not found sufficient evidence to modify the current reputation of the submission; we cannot change the submission’s reputation because it can negatively affect our customers. However, a customer has the option of locally changing a submission’s reputation, if they understand the risks in doing so. Please open a TAC case and provide additional details if you need further assistance."
    Then I uncheck checkbox with class "dispute-entry-checkbox_1"
    Then I check checkbox with class "dispute-entry-checkbox_2"
    And I click "#index-entry-status-button"
    And I click "#ENTRY_RESOLVED_CLOSED"
    #Should not pre-populate for email type submission
    And I click "#ENTRY_FIXED_FP"
    Then I should not see "Talos has concluded that the submission is safe to access at this time; the submission’s reputation has been improved. This update will be publicly visible in the next 24 hours. If your device or endpoint client is not reflecting this disposition, please open a TAC case."
    When I click "#ENTRY_FIXED_FN"
    Then I should not see "Talos has concluded that the submission is unsafe to access at this time due to malicious activity; the submission’s reputation has been decreased. This update will be publicly visible in the next 24 hours. If your device or endpoint client is not reflecting this disposition, please open a TAC case."
    When I click "#ENTRY_UNCHANGED"
    Then I should not see "Talos has not found sufficient evidence to modify the current reputation of the submission; we cannot change the submission’s reputation because it can negatively affect our customers. However, a customer has the option of locally changing a submission’s reputation, if they understand the risks in doing so. Please open a TAC case and provide additional details if you need further assistance."
    Then I uncheck checkbox with class "dispute-entry-checkbox_2"
    Then I check checkbox with class "dispute-entry-checkbox_3"
    And I click "#index-entry-status-button"
    And I click "#ENTRY_RESOLVED_CLOSED"
    #Messages change for guest submissions
    And I click "#ENTRY_FIXED_FP"
    Then I should see "Talos has concluded that the submission is safe to access at this time; the submission’s reputation has been improved. This update will be publicly visible in the next 24 hours."
    When I click "#ENTRY_FIXED_FN"
    Then I should see "Talos has concluded that the submission is unsafe to access at this time due to malicious activity; the submission’s reputation has been decreased. This update will be publicly visible in the next 24 hours."
    When I click "#ENTRY_UNCHANGED"
    Then I should see "Talos has not found sufficient evidence to modify the current reputation of the submission; we cannot change the submission’s reputation because it can negatively affect our customers. However, a customer has the option of locally changing a submission’s reputation, if they understand the risks in doing so."
    Then I check checkbox with class "dispute-entry-checkbox_2"
    And I click "#index-entry-status-button"
    And I click "#ENTRY_RESOLVED_CLOSED"
    #Should not pre-populate for email type submission
    And I click "#ENTRY_FIXED_FP"
    Then I should not see "Talos has concluded that the submission is safe to access at this time; the submission’s reputation has been improved. This update will be publicly visible in the next 24 hours. If your device or endpoint client is not reflecting this disposition, please open a TAC case."
    When I click "#ENTRY_FIXED_FN"
    Then I should not see "Talos has concluded that the submission is unsafe to access at this time due to malicious activity; the submission’s reputation has been decreased. This update will be publicly visible in the next 24 hours. If your device or endpoint client is not reflecting this disposition, please open a TAC case."
    When I click "#ENTRY_UNCHANGED"
    Then I should not see "Talos has not found sufficient evidence to modify the current reputation of the submission; we cannot change the submission’s reputation because it can negatively affect our customers. However, a customer has the option of locally changing a submission’s reputation, if they understand the risks in doing so. Please open a TAC case and provide additional details if you need further assistance."


  @javascript
  Scenario: a user picks a resolution for a ticket and the comment is pre-populated
    Given a user with role "webrep user" exists and is logged in
    And a guest company exists
    And the following customers exist:
      | id | company_id |   name   | email                 |
      | 3  |      1     |  guest   | guest@guest.com       |
      | 4  |      2     | customer | customer@customer.com |
    Given the following disputes exist:
      | id | submission_type |   submitter_type   | customer_id |
      | 1  |        w        |    CUSTOMER        |     4       |
      | 2  |        e        |    CUSTOMER        |     4       |
      | 3  |        w        |    NON-CUSTOMER    |     3       |
    When I goto "escalations/webrep/disputes/1/"
    And I click "#show-edit-ticket-status-button"
    And I click "#RESOLVED_CLOSED"
    #Should show full messages for customer submissions
    And I click "#FIXED_FP"
    Then I should see "Talos has concluded that the submission is safe to access at this time; the submission’s reputation has been improved. This update will be publicly visible in the next 24 hours. If your device or endpoint client is not reflecting this disposition, please open a TAC case."
    When I click "#FIXED_FN"
    Then I should see "Talos has concluded that the submission is unsafe to access at this time due to malicious activity; the submission’s reputation has been decreased. This update will be publicly visible in the next 24 hours. If your device or endpoint client is not reflecting this disposition, please open a TAC case."
    When I click "#UNCHANGED"
    Then I should see "Talos has not found sufficient evidence to modify the current reputation of the submission; we cannot change the submission’s reputation because it can negatively affect our customers. However, a customer has the option of locally changing a submission’s reputation, if they understand the risks in doing so. Please open a TAC case and provide additional details if you need further assistance."
    When I goto "escalations/webrep/disputes/2/"
    And I click "#show-edit-ticket-status-button"
    And I click "#RESOLVED_CLOSED"
    #Should not pre-populate for email type submission
    And I click "#FIXED_FP"
    Then I should not see "Talos has concluded that the submission is safe to access at this time; the submission’s reputation has been improved. This update will be publicly visible in the next 24 hours. If your device or endpoint client is not reflecting this disposition, please open a TAC case."
    When I click "#FIXED_FN"
    Then I should not see "Talos has concluded that the submission is unsafe to access at this time due to malicious activity; the submission’s reputation has been decreased. This update will be publicly visible in the next 24 hours. If your device or endpoint client is not reflecting this disposition, please open a TAC case."
    When I click "#UNCHANGED"
    Then I should not see "Talos has not found sufficient evidence to modify the current reputation of the submission; we cannot change the submission’s reputation because it can negatively affect our customers. However, a customer has the option of locally changing a submission’s reputation, if they understand the risks in doing so. Please open a TAC case and provide additional details if you need further assistance."
    When I goto "escalations/webrep/disputes/3/"
    And I click "#show-edit-ticket-status-button"
    And I click "#RESOLVED_CLOSED"
    #Messages change for guest submissions
    And I click "#FIXED_FP"
    Then I should see "Talos has concluded that the submission is safe to access at this time; the submission’s reputation has been improved. This update will be publicly visible in the next 24 hours."
    When I click "#FIXED_FN"
    Then I should see "Talos has concluded that the submission is unsafe to access at this time due to malicious activity; the submission’s reputation has been decreased. This update will be publicly visible in the next 24 hours."
    When I click "#UNCHANGED"
    Then I should see "Talos has not found sufficient evidence to modify the current reputation of the submission; we cannot change the submission’s reputation because it can negatively affect our customers. However, a customer has the option of locally changing a submission’s reputation, if they understand the risks in doing so."


  @javascript
  Scenario: a user picks a resolution for an entry and the comment is pre-populated
    Given a user with role "webrep user" exists and is logged in
    And a guest company exists
    And the following customers exist:
      | id | company_id |   name   | email                 |
      | 3  |      1     |  guest   | guest@guest.com       |
      | 4  |      2     | customer | customer@customer.com |
    Given the following disputes exist and have entries:
      | id | submission_type |   submitter_type   | customer_id |
      | 1  |        w        |    CUSTOMER        |     4       |
      | 2  |        e        |    CUSTOMER        |     4       |
      | 3  |        w        |    NON-CUSTOMER    |     3       |
    When I goto "escalations/webrep/disputes/1/"
    And I wait for "10" seconds
    Then I click "#research-tab-link"
    Then I check checkbox with class "dispute-entry-cb-1"
    And I click "#edit-dispute-entry-button"
    And I click "#entry_status_button_1"
    And I click "#RESOLVED_CLOSED"
    #Should show full messages for customer submissions
    And I click "#ENTRY_FIXED_FP"
    Then I should see "Talos has concluded that the submission is safe to access at this time; the submission’s reputation has been improved. This update will be publicly visible in the next 24 hours. If your device or endpoint client is not reflecting this disposition, please open a TAC case."
    When I click "#ENTRY_FIXED_FN"
    Then I should see "Talos has concluded that the submission is unsafe to access at this time due to malicious activity; the submission’s reputation has been decreased. This update will be publicly visible in the next 24 hours. If your device or endpoint client is not reflecting this disposition, please open a TAC case."
    When I click "#ENTRY_UNCHANGED"
    Then I should see "Talos has not found sufficient evidence to modify the current reputation of the submission; we cannot change the submission’s reputation because it can negatively affect our customers. However, a customer has the option of locally changing a submission’s reputation, if they understand the risks in doing so. Please open a TAC case and provide additional details if you need further assistance."
    When I goto "escalations/webrep/disputes/2/"
    Then I click "#research-tab-link"
    Then I check checkbox with class "dispute-entry-cb-2"
    And I click "#edit-dispute-entry-button"
    And I click "#entry_status_button_2"
    And I click "#RESOLVED_CLOSED"
    And I click "#ENTRY_FIXED_FP"
    Then I should not see "Talos has concluded that the submission is safe to access at this time; the submission’s reputation has been improved. This update will be publicly visible in the next 24 hours. If your device or endpoint client is not reflecting this disposition, please open a TAC case."
    When I click "#ENTRY_FIXED_FN"
    Then I should not see "Talos has concluded that the submission is unsafe to access at this time due to malicious activity; the submission’s reputation has been decreased. This update will be publicly visible in the next 24 hours. If your device or endpoint client is not reflecting this disposition, please open a TAC case."
    When I click "#ENTRY_UNCHANGED"
    Then I should not see "Talos has not found sufficient evidence to modify the current reputation of the submission; we cannot change the submission’s reputation because it can negatively affect our customers. However, a customer has the option of locally changing a submission’s reputation, if they understand the risks in doing so. Please open a TAC case and provide additional details if you need further assistance."
    When I goto "escalations/webrep/disputes/3/"
    Then I click "#research-tab-link"
    Then I check checkbox with class "dispute-entry-cb-3"
    And I click "#edit-dispute-entry-button"
    And I click "#entry_status_button_3"
    And I click "#RESOLVED_CLOSED"
    And I click "#ENTRY_FIXED_FP"
    Then I should see "Talos has concluded that the submission is safe to access at this time; the submission’s reputation has been improved. This update will be publicly visible in the next 24 hours."
    When I click "#ENTRY_FIXED_FN"
    Then I should see "Talos has concluded that the submission is unsafe to access at this time due to malicious activity; the submission’s reputation has been decreased. This update will be publicly visible in the next 24 hours."
    When I click "#ENTRY_UNCHANGED"
    Then I should see "Talos has not found sufficient evidence to modify the current reputation of the submission; we cannot change the submission’s reputation because it can negatively affect our customers. However, a customer has the option of locally changing a submission’s reputation, if they understand the risks in doing so."


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
    Then I click "#cancel-add-criteria"
    And I click "#submit-advanced-search"
    Then I click ".export-all-btn"
    # Thomas Walpole says that selenium driver does not provide access to response headers
    # https://stackoverflow.com/questions/55584140/capybara-fails-with-notsupportedbydrivererror
    # Then I wait for "3" seconds
    # Then I should receive a file of type "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"'

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
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id | submission_type |
      | 1  | w               |
    When I goto "escalations/webrep/disputes?f=all"
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
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id | submission_type |
      | 1  | w               |
    When I goto "escalations/webrep/disputes?f=all"
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
    When I goto "escalations/webrep/disputes?f=all"
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
    Given a user with role "webrep user" exists and is logged in
    Given the following disputes exist:
      | id | submission_type | status    |
      | 1  | w               | ESCALATED |
      | 2  | e               | PENDING   |
    And the following dispute_entries exist:
      | dispute_id   | uri             | entry_type |
      | 1            | whatever.com    | URI/DOMAIN |
      | 2            | iamatest.com    | URI/DOMAIN |
    When I goto "escalations/webrep/disputes?f=all"
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
    # Note that selenium doesn't support viewing response headers as is required by this test, maybe just get rid of it
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id | submission_type |
      | 1  | w               |
    When I goto "escalations/webrep/disputes?f=open"
    And I click ".dispute_check_box"
    And I click ".export-selected-btn"
    # Thomas Walpole says that selenium driver does not provide access to response headers
    # https://stackoverflow.com/questions/55584140/capybara-fails-with-notsupportedbydrivererror
    # Then I wait for "3" seconds
    # Then I should receive a file of type "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

  @javascript
  Scenario: a user wants to do an advanced search and ensure those previous values are cleared on subsequent search
    Given a user with role "webrep user" exists and is logged in
    Given the following disputes exist:
      | id       | submission_type | status    |
      | 1        | w               | ESCALATED |
      | 2000002  | e               | PENDING   |
    And the following dispute_entries exist:
      | dispute_id   | ip_address     | entry_type |
      | 1            | 162.219.31.5   | IP         |
      | 2000002      | 162.219.31.5   | IP         |
    When I goto "escalations/webrep/disputes/1"
    Then I click "#research-tab-link"
    Then I click button with class "show_references"
    And  I click "2000002"
    And  I wait for "5" seconds
    And  I should see "0002000002"
    And I should see "PENDING"


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
    # Note that selenium doesn't support viewing response headers as is required by this test, maybe just get rid of it
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id |
      | 1  |
    When I goto "/escalations/webrep/disputes/1"
    And I click "#research-tab-link"
    And I click ".dispute_check_box"
    And I click "Export Selected to CSV"
    # Thomas Walpole says that selenium driver does not provide access to response headers
    # https://stackoverflow.com/questions/55584140/capybara-fails-with-notsupportedbydrivererror
    #Then I wait for "3" seconds
    #Then I should receive a file of type "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

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
    And I wait for "5" seconds
    Then I should see content "cisco.com" within ".entry-data-content"

    And I should see content "WL-med" within ".entry-data-wlbl"
    And I should see content "BL-heavy" within ".entry-data-wlbl"


  # Gathering resolved host ip on creation / additional query to sdsv3 for url+ip data
  @javascript
  Scenario: a user creates a new dispute ticket and the entry returns with a resolved host ip
    Given a user with role "webrep user" exists and is logged in
    And bugzilla rest api always saves
    And the following disputes exist:
      | id   |
      | 5370 |
    And the following customers exist:
      |id| name            |
      |1 | Dispute Analyst |
    And  I goto "/escalations/webrep/disputes"
    And  I wait for "3" seconds
    Then I click "#new-dispute"
    And  I wait for "1" seconds
#    WHY IS THERE A COMMA IN THIS STEP DEF?
    And  I fill in element, "#ips_urls" with "petful.com"
    And  I click button "submit"
    And  I wait for "10" seconds
    And  I click button with class "close"
    And  I wait for "3" seconds
    Then I click "0000005370"
    And  I wait for "5" seconds
    Then I click "#research-tab-link"
    And  I wait for "3" seconds
#    And  Element with class "entry-resolved-ip-content" should not be empty
#    And I should see a resolved host ip etc.



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

  @javascript
  Scenario: left nav links should apply filter if the filter was set before
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |  id       |  status         | user_id |
      | 000001    | ASSIGNED        |    1    |
      | 000002    | RESOLVED_CLOSED |    1    |
    When I goto "/escalations/webrep/disputes?f=open"
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
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |  id       |  status         | user_id |
      | 000001    | ASSIGNED        |    1    |
      | 000002    | RESOLVED_CLOSED |    1    |
    When I goto "/escalations/webrep/disputes?f=open"
    Then I should see "000001"
    And I should not see "000002"
    When I click "#queue"
    Then I should see "000001"
    And I should not see "000002"


#*********************************************#

# Converting Webrep ticket to Webcat (WEB-4413)

  @javascript
  Scenario: a user tries to convert a webrep ticket to a webcat ticket
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |  id       |  status         | user_id |
      | 000001    | ASSIGNED        |    1    |
    When I goto "/escalations/webrep/disputes?f=open"
    And I wait for "2" seconds
    And I click "#cbox0000000001"
    And I click "#convert-ticket-button"
    And I wait for "1" seconds
    And I should see "talosintelligence.com"
#    And I click "#1-selectize-selectized"
    And I fill in selectized of element "#1-selectize" with "['6', '77']"
    And I wait for "1" seconds
    And I click ".dropdown-submit-button"
    And I wait for "1" seconds
    And I should see "Reputation Dispute converted to Categorization Complaint."

  @javascript
  Scenario: a user tries to convert a webrep ticket to a webcat ticket that is not in an open status
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      |  id       |  status        | user_id |
      | 000001    | ON_HOLD        |    1    |
    When I goto "/escalations/webrep/disputes?f=open"
    And I wait for "2" seconds
    And I click "#cbox0000000001"
    And I click "#convert-ticket-button"
    And I wait for "1" seconds
    And I should see "TICKET CANNOT BE CONVERTED"
