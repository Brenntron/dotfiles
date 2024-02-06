Feature: Webcat complaints index
  In order to manage webcat complaints
  I will provide a complaints interface

  Background:
    Given a guest company exists


  @javascript
  Scenario: a user with webcat permissions can visit the webcat section and see complaints
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type | status     |
      | 1  | abc.com        | abc.com         | URI/DOMAIN | NEW        |
      | 2  | url.com        | url.com         | URI/DOMAIN | ASSIGNED   |
      | 3  | test.com       | test.com        | URI/DOMAIN | ASSIGNED   |
    Then I goto "escalations/webcat/complaints"
    And I wait for "2" seconds
    And I should see "abc.com"
    And I should see "url.com"
    And I should see "test.com"


  @javascript
  Scenario: a user can open a selected entry in a new tab
    Given a user with role "webcat user" exists and is logged in
    And a complaint entry with trait "not_important" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "2" seconds
    And  I click ".cat-index-main-row"
    When I click ".open-selected"
    And I wait for "5" seconds
    Then a new window should be opened
    When I switch to the new window
    And I should see "Google in the U.S."

  @javascript
  Scenario: a user can open multiple selected entries in new tabs
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri            | domain          | entry_type | status |
      | 111 | abc.com        | abc.com         | URI/DOMAIN | NEW    |
      | 222 | google.com     | google.com      | URI/DOMAIN | NEW    |
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "2" seconds
    And  I click row with id "111"
    And  I click row with id "222"
    When I click ".open-selected"
    And I wait for "5" seconds
    Then "2" new windows should be opened

  @javascript
  Scenario: a user cannot open a selected entry with a low WBRS Score (less than -6)
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type | status     | wbrs_score |
      | 1  | abc.com        | abc.com         | URI/DOMAIN | NEW        |   -6.3     |
    Then I goto "escalations/webcat/complaints"
    And I wait for "2" seconds
    And  I click ".cat-index-main-row"
    When I click ".open-selected"
    And I wait for "2" seconds
    And I should see "could not open due to low WBRS Scores"

  @javascript
  Scenario: a user can use the 'Open All' button to open multiple entries in new tabs
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri            | domain          | entry_type | status |
      | 111 | abc.com        | abc.com         | URI/DOMAIN | NEW    |
      | 222 | google.com     | google.com      | URI/DOMAIN | NEW    |
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "2" seconds
    When I click "#toolbar-open-all"
    And I wait for "2" seconds
    And I accept the user prompt
    And I wait for "2" seconds
    Then "2" new windows should be opened

  @javascript
  Scenario: a user can open a url that does not have a low WBRS score using the Open URL button within the row of that entry
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri            | domain          | entry_type | status | wbrs_score |
      | 111 | abc.com        | abc.com         | URI/DOMAIN | NEW    | 0.0        |
      | 222 | google.com     | google.com      | URI/DOMAIN | NEW    | 2.5        |
      | 333 | badurl.com     | badurl.com      | URI/DOMAIN | NEW    | -7.8       |
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "2" seconds
    And I click "#open-111"
    And I wait for "2" seconds
    Then a new window should be opened

  @javascript
  Scenario: a user cannot open a url with a low WBRS score using the Open URL button within the row of that entry
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri            | domain          | entry_type | status | wbrs_score |
      | 111 | abc.com        | abc.com         | URI/DOMAIN | NEW    | 0.0        |
      | 222 | google.com     | google.com      | URI/DOMAIN | NEW    | 2.5        |
      | 333 | badurl.com     | badurl.com      | URI/DOMAIN | NEW    | -7.8       |
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "2" seconds
    And button with id "open-333" should be disabled

  @javascript
  Scenario: a user can click a button to do a google search on an entry
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri            | domain          | entry_type | status | wbrs_score |
      | 111 | abc.com        | abc.com         | URI/DOMAIN | NEW    | 0.0        |
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "2" seconds
    And I click "#google-111"
    And I wait for "2" seconds
    Then a new window should be opened

  @javascript
  Scenario: a user looks at the the history of an entry
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri            | domain          | entry_type | status | wbrs_score |
      | 111 | abc.com        | abc.com         | URI/DOMAIN | NEW    | 0.0        |
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "2" seconds
    And I click "#entry-history-111"
    And I wait for "2" seconds
    And I should see "History Information"
    And I should see "COMPLAINT ENTRY HISTORY"
    And I should see "XBRS TIMELINE"

  @javascript
  Scenario: user should retrieve ICANN whois data for complaint entries on the webcat/complaints index page.
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      |id|  domain      | status |
      |1 | food.com     |  NEW   |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#whois-1"
    And I wait for the ajax request to finish
    Then I should see "DOMAIN NAME"
    And I should see "FOOD.COM"
    And I should see "REGISTRANT"
    And I should see "NAME SERVERS"


  # Bulk Submit tests #
  @javascript
  Scenario: bulk submit submits all selected complaint entries
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status |
      | 111 | food.com     | food.com      | URI/DOMAIN | NEW    |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |
    And I goto "/escalations/webcat/complaints?f=NEW"
    And I wait for "2" seconds
    And I fill in "input_cat_111-selectized" with "Arts" and press enter
    And I fill in "input_cat_222-selectized" with "Education" and press enter
    When I click "master-submit"
    And I wait for "5" seconds
    And I click "#bulk-submit-correct-btn"
    And I wait for "5" seconds
    And I should see "SUCCESS"
    And I dismiss modal "#msg-modal" if needed
    And I wait for "5" seconds
    Then I should not see "food.com"
    And I should not see "blah.com"



#    TODO
#  Scenario: user tries to submit bulk selected entries with Fixed resolution that do not have a category
#  Scenario: user tries to submit bulk selected entries with Invalid resolution
  # Scenario: user tries to submit bulk selected entries with Unchanged resolution
  # Scenario: user tries to submit bulk selected entries with Invalid resolution and a category
  # Scenario: user tries to submit bulk selected entries with Unchanged resolution and a category




  # TODO - this does not work in testing env yet - the pop up does not prevent refresh
  # might need tweaks to testing browser
  @javascript
  Scenario: a user sees a pop-up window if they make changes to an entry but do not submit
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status |
      | 111 | food.com     | food.com      | URI/DOMAIN | NEW    |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |
    And I goto "/escalations/webcat/complaints?f=NEW"
    And I wait for "2" seconds
    And I fill in "input_cat_111-selectized" with "Arts" and press enter
    And pending
#    And I refresh the page
#    And I wait for "3" seconds
#    And take a screenshot


  @javascript
  Scenario: a users tries to fetch complaints
    Given a user with role "webcat user" exists and is logged in
    And PeakeBridge poll is stubbed
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#fetch"
    Then I wait for "3" seconds
    Then I should see "COMPLAINT UPDATES REQUESTED FROM TALOS-INTELLIGENCE."

  @javascript
  Scenario: a users tries to fetch WBNP data
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#fetch_wbnp"
    And I wait for "10" seconds
    Then I should see content "Active" within ".wbnp-report-status"



  # Submitting individual entries ###############

  @javascript
  Scenario: a user submits an individual entry with a new category and a Fixed resolution
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status |
      | 111 | food.com     | food.com      | URI/DOMAIN | NEW    |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |
    When I goto "/escalations/webcat/complaints?f=NEW"
    And I wait for "3" seconds
    And I should see "food.com"
    And I should see "blah.com"
    And I fill in selectized of element "#input_cat_111" with "['77']"
    And I click "#submit_changes_111"
    And I wait for "2" seconds
    And I should see "Submitted"
    And I refresh the page
    And I should not see "food.com"
    Then I goto "/escalations/webcat/complaints?f=COMPLETED"
    And I should see "Alcohol"
    And I wait for "6" seconds


  @javascript
  Scenario: a user submits an individual entry with a changed category and a Fixed resolution
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status | url_primary_category | category               |
      | 111 | food.com     | food.com      | URI/DOMAIN | NEW    | Health and Medicine  | Health and Medicine    |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |                      |                        |
    When I goto "/escalations/webcat/complaints?f=NEW"
    And I wait for "5" seconds
    And I should see "food.com"
    And I should see "blah.com"
    And I fill in selectized of element "#input_cat_111" with "['77']"
    And I wait for "3" seconds
    And I click "#submit_changes_111"
    And I wait for "2" seconds
    And I should see "Submitted"
    And I refresh the page
    And I should not see "food.com"
    Then I goto "/escalations/webcat/complaints?f=COMPLETED"
    And I should see "Alcohol"
    And I should not see "Health and Medicine"


  @javascript
  Scenario: a user cannot submit an individual entry with no categories and a Fixed resolution
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status |
      | 111 | food.com     | food.com      | URI/DOMAIN | NEW    |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |
    When I goto "/escalations/webcat/complaints?f=NEW"
    And I wait for "3" seconds
    And I should see "food.com"
    And I should see "blah.com"
    And I click "#submit_changes_111"
    And I wait for "5" seconds
    And I should see "MUST INCLUDE AT LEAST ONE CATEGORY"


  @javascript
  Scenario: a user submits an individual entry with an Unchanged resolution, and tries to add a new category that will not be saved
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status |
      | 111 | food.com     | food.com      | URI/DOMAIN | NEW    |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "3" seconds
    And I should see "food.com"
    And I should see "blah.com"
    And I click "#unchanged111"
    And I fill in selectized of element "#input_cat_111" with "['77']"
    And I should see "Alcohol"
    And I wait for "1" seconds
    And I click "#submit_changes_111"
    And I wait for "5" seconds
    And I refresh the page
    And I should not see "Alcohol"


  # TODO - backend is throwing an error and looking for a category when one should not be required
  @javascript
  Scenario: a user correctly submits an individual entry with an Unchanged resolution and no category
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status |
      | 111 | food.com     | food.com      | URI/DOMAIN | NEW    |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "3" seconds
    And I should see "food.com"
    And I should see "blah.com"
    And I click "#unchanged111"
    And I wait for "1" seconds
    And I click "#submit_changes_111"
    And I wait for "5" seconds
    And I should see "Submitted"
    Then I goto "/escalations/webcat/complaints?f=COMPLETED"
    And I wait for "3" seconds
    And I should see "food.com"
    And I should not see "blah.com"


  @javascript
  Scenario: a user submits an individual entry with an Unchanged resolution that maintains its initial category
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status | url_primary_category | category               |
      | 111 | food.com     | food.com      | URI/DOMAIN | NEW    | Health and Medicine  | Health and Medicine    |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |                      |                        |
    When I goto "/escalations/webcat/complaints?f=NEW"
    And I wait for "5" seconds
    And I should see "food.com"
    And I should see "blah.com"
    And I click "#unchanged111"
    And I wait for "1" seconds
    And I click "#submit_changes_111"
    And I wait for "5" seconds
    And I should see "Submitted"
    Then I goto "/escalations/webcat/complaints?f=COMPLETED"
    And I wait for "8" seconds
    And I should see "food.com"
    And I should see "Health and Medicine"
    And I should not see "blah.com"


  @javascript
  Scenario: a user cannot submit an individual entry with an Invalid resolution and a new category
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status |
      | 111 | food.com     | food.com      | URI/DOMAIN | NEW    |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "3" seconds
    And I should see "food.com"
    And I should see "blah.com"
    And I click "#invalid111"
    And I fill in selectized of element "#input_cat_111" with "['77']"
    And I should see "Alcohol"
    And I wait for "1" seconds
    And I click "#submit_changes_111"
    And I wait for "5" seconds
    And I should see "CANNOT INCLUDE CATEGORIES WITH AN INVALID RESOLUTION"

  @javascript
  Scenario: a user correctly submits an individual entry with an Invalid resolution and no category
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status |
      | 111 | food.com     | food.com      | URI/DOMAIN | NEW    |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "3" seconds
    And I should see "food.com"
    And I should see "blah.com"
    And I click "#invalid111"
    And I wait for "1" seconds
    And I click "#submit_changes_111"
    And I wait for "5" seconds
    And I should see "Submitted"
    Then I goto "/escalations/webcat/complaints?f=COMPLETED"
    And I wait for "3" seconds
    And I should see "food.com"
    And I should not see "blah.com"


  @javascript
  Scenario: a user submits a non-high traffic entry and it gets resolved and does not go into the Review queue
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status | is_important |
      | 111 | food.com     | food.com      | URI/DOMAIN | NEW    |      0       |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |      0       |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "3" seconds
    And I should see "food.com"
    And I should see "blah.com"
    And I click "#unchanged111"
    And I click "#submit_changes_111"
    And I wait for "5" seconds
    And take a screenshot
    And I should see "Submitted"
    And I fill in selectized of element "#input_cat_222" with "['77']"
    And I click "#submit_changes_222"
    And I wait for "5" seconds
    Then I goto "/escalations/webcat/complaints?f=COMPLETED"
    And I should see "food.com"
    And I should see "blah.com"
    Then I goto "/escalations/webcat/complaints?f=REVIEW"
    And I wait for "3" seconds
    And I should not see "food.com"
    And I should not see "blah.com"


  @javascript
  Scenario: a user submits a high traffic (important) entry and it goes into the Review queue
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status | is_important |
      | 111 | food.com     | food.com      | URI/DOMAIN | NEW    |      1       |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |      1       |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "3" seconds
    And I should see "food.com"
    And I should see "blah.com"
    And I fill in selectized of element "#input_cat_222" with "['77']"
    And I click "#submit_changes_222"
    Then I goto "/escalations/webcat/complaints?f=REVIEW"
    And I wait for "3" seconds
    And I should not see "food.com"
    And I should see "blah.com"

  @javascript
  Scenario: a reviewer commits a FIXED PENDING entry
    Given a user with role "webcat manager" exists and is logged in
    And the following users exist
      | id  | display_name    |
      | 123 | Wembly Catalyst |
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status     | url_primary_category | resolution | user_id | is_important |
      | 111 | food.com     | food.com      | URI/DOMAIN | PENDING    | Health and Medicine  |            |         |       0      |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | PENDING    | Arts                 | FIXED      |    123  |       1      |
    When I goto "/escalations/webcat/complaints?f=REVIEW"
    And I wait for "3" seconds
    And I click row with id "222"
    And I click "#assignment-type-reviewer"
    And I click ".take-ticket-toolbar-button"
    And I wait for "3" seconds
    And I click "#commit222"
    And I click "#submit_changes_222"
    And I wait for "2" seconds
    Then I goto "/escalations/webcat/complaints?f=COMPLETED"
    And I wait for "3" seconds
    And take a screenshot
    And I should see "blah.com"
    And I should see "Arts"
    And I should not see "food.com"

  @javascript
  Scenario: a reviewer commits an UNCHANGED PENDING entry
    Given a user with role "webcat manager" exists and is logged in
    And the following users exist
      | id  | display_name    |
      | 123 | Wembly Catalyst |
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status     | url_primary_category | resolution | user_id | is_important |
      | 111 | food.com     | food.com      | URI/DOMAIN | PENDING    | Health and Medicine  |            |         |       0      |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | PENDING    | Arts                 | UNCHANGED  |    123  |       1      |
    When I goto "/escalations/webcat/complaints?f=REVIEW"
    And I wait for "3" seconds
    And I click row with id "222"
    And I click "#assignment-type-reviewer"
    And I click ".take-ticket-toolbar-button"
    And I wait for "3" seconds
    And I click "#commit222"
    And I click "#submit_changes_222"
    And I wait for "2" seconds
    Then I goto "/escalations/webcat/complaints?f=COMPLETED"
    And I wait for "3" seconds
    And take a screenshot
    And I should see "blah.com"
    And I should see "Arts"
    And I should not see "food.com"


  @javascript
  Scenario: a reviewer declines a PENDING entry (and that entry then goes back into ASSIGNED queue)
    Given a user with role "webcat manager" exists and is logged in
    And the following users exist
    | id  | display_name   |
    | 123 | Webby Catalyst |
    And the following complaint entries exist:
      | id  | uri       | domain    | entry_type | status  | url_primary_category | category              | resolution | user_id | is_important |
      | 111 | food.com  | food.com  | URI/DOMAIN | NEW     | Health and Medicine  | Health and Medicine   |            |         |       0      |
      | 222 | blah.com  | blah.com  | URI/DOMAIN | PENDING | Arts                 |                       | FIXED      |    123  |       1      |
    When I goto "/escalations/webcat/complaints?f=REVIEW"
    And I wait for "3" seconds
    And I click row with id "222"
    And I click "#assignment-type-reviewer"
    And I click ".take-ticket-toolbar-button"
    And I wait for "3" seconds
    And I click "#decline222"
    And I click "#submit_changes_222"
    And I wait for "2" seconds
    When I goto "/escalations/webcat/complaints?f=COMPLETED"
    And I wait for "3" seconds
    And I should not see "blah.com"
    And I should not see "food.com"
    Then I goto "/escalations/webcat/complaints?f=ASSIGNED"
    And I wait for "3" seconds
    And I should see "blah.com"
#    And I should not see "food.com" <- TODO got a filter problem here
    And I should not see "Arts"



  # Scenario: a user cannot submit an individual entry with no changes to categories and a Fixed resolution
  # Scenario: a user submits an individual entry with no category changes and an Unchanged resolution
  # Scenario: a user submits an individual entry with no category changes and an Invalid resolution

# a non-manager can view pending entries
  # a non-manager cannot commit pending entries



  @javascript
  Scenario: a user can show/hide columns in the webcat/complaints view
    Given a user with role "webcat user" exists and is logged in
    And the following companies exist:
      | id | name                    |
      | 5  | Gilligan's Co.          |
      | 7  | Western Investigations  |
    And the following customers exist:
      | id | name                | company_id | email                    |
      | 12 | Maryanne Summers    |     5      | msummers@islandtours.com |
      | 13 | Ginger Grant        |     5      | ggrant@islandtours.com   |
      | 14 | Brisco County, Jr.  |     7      | bcjr@wpi.com             |
      | 15 | Dixie Cousins       |     7      | dxc@wpi.com              |
    And the following platforms exist:
      | id | public_name       | internal_name     | webcat |
      | 1  | TalosIntelligence | TalosIntelligence |   1    |
    And the following complaints exist:
      | id   | description        | customer_id | submitter_type | ticket_source      |
      | 5111 | weather            |      12     | CUSTOMER       | talos-intelligence |
      | 5112 | travel site        |      13     | CUSTOMER       | talos-intelligence |
      | 5113 | John Bly owns this |      14     | CUSTOMER       | talos-intelligence |
      | 5114 | Unknown origin     |      15     | CUSTOMER       | talos-intelligence |
    And the following complaint entries exist:
      | id   | complaint_id | uri                    | domain                | entry_type | status | platform_id |
      | 9111 | 5111         | hurricaneshere.com     | hurricaneshere.com    | URI/DOMAIN | NEW    |      1      |
      | 9222 | 5112         | tinyhiddenislands.com  | tinyhiddenislands.com | URI/DOMAIN | NEW    |      1      |
      | 9333 | 5113         | evilmastermind.com     | evilmastermind.com    | URI/DOMAIN | NEW    |      1      |
      | 9444 | 5114         | timetravelingorb.com   | timetravelingorb.com  | URI/DOMAIN | NEW    |      1      |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "3" seconds
    And take a screenshot
    When I click "#webcat-index-table-show-columns-button"
    And I wait for "2" seconds



  @javascript
  Scenario: a user can ensure show/hide column states are saved in the database after a page reload
    Given a user with role "webcat user" exists and is logged in
    And the following disputes exist and have entries:
      | id | submitter_type |
      | 1  | CUSTOMER       |
    Then I goto "escalations/webcat/complaints"
    And I wait for "2" seconds
    And I click "#webcat-index-table-show-columns-button"
    And I should see the ".subdomain-checkbox" checkbox checked
    And I should see the ".assignee-checkbox" checkbox checked
    And I click ".subdomain-checkbox"
    And I click ".assignee-checkbox"
    Then I should not see table header with id "subdomain"
    Then I should not see table header with id "assignee"
    Then I should see table header with id "tags"
    Then I should see table header with id "path"
    And I goto "escalations/webcat/complaints"
    And I wait for "2" seconds
    Then I should not see table header with id "subdomain"
    Then I should not see table header with id "assignee"
    Then I should see table header with id "tags"
    Then I should see table header with id "path"