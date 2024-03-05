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


  @javascript
  Scenario: the bulk submit button is disabled if there have been no changes to entries
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status |
      | 111 | food.com     | food.com      | URI/DOMAIN | NEW    |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |
    And I goto "/escalations/webcat/complaints?f=NEW"
    And I wait for "2" seconds
    And button with id "master-submit" should be disabled


  ### Bulk Fixed Resolution scenarios
  @javascript
  Scenario: a user tries to submit bulk entries with Fixed resolution but no category
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status |
      | 111 | food.com     | food.com      | URI/DOMAIN | NEW    |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |
    And I goto "/escalations/webcat/complaints?f=NEW"
    And I wait for "2" seconds
    And button with id "master-submit" should be disabled
    And I fill in "input_cat_111-selectized" with "Arts" and press enter
    And I wait for "1" seconds
    And button with id "master-submit" should be enabled
    And I clear element "#input_cat_111-selectized"
    And I click "#master-submit"
    And I wait for "3" seconds
    And I should see "THE FOLLOWING ENTRIES ARE INCOMPLETE OR INCORRECT"
    And button with id "bulk-submit-correct-btn" should be disabled

  @javascript
  Scenario: a user can submit bulk entries with Fixed resolution and an added category
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status |
      | 111 | food.com     | food.com      | URI/DOMAIN | NEW    |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |
    And I goto "/escalations/webcat/complaints?f=NEW"
    And I wait for "2" seconds
    And button with id "master-submit" should be disabled
    And I fill in "input_cat_111-selectized" with "Arts" and press enter
    And I wait for "1" seconds
    And button with id "master-submit" should be enabled
    And I click "#master-submit"
    And I wait for "3" seconds
    And I should see "THE FOLLOWING ENTRIES ARE READY TO BE SUBMITTED"
    And button with id "bulk-submit-correct-btn" should be enabled
    And I click "#bulk-submit-correct-btn"
    And I wait for "3" seconds
    And I should see "All entries successfully processed."


  @javascript
  Scenario: a user can submit bulk entries with Fixed resolution and a changed category
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status | url_primary_category | category               |
      | 111 | food.com     | food.com      | URI/DOMAIN | NEW    | Health and Medicine  | Health and Medicine    |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |                      |                        |
    And I goto "/escalations/webcat/complaints?f=NEW"
    And I wait for "2" seconds
    And button with id "master-submit" should be disabled
    And I clear element "#input_cat_111-selectized"
    And I fill in "input_cat_111-selectized" with "Arts" and press enter
    And I wait for "1" seconds
    And button with id "master-submit" should be enabled
    And I click "#master-submit"
    And I wait for "3" seconds
    And I should see "THE FOLLOWING ENTRIES ARE READY TO BE SUBMITTED"
    And button with id "bulk-submit-correct-btn" should be enabled
    And I click "#bulk-submit-correct-btn"
    And I wait for "3" seconds
    And I should see "All entries successfully processed."


  @javascript
  Scenario: a user can submit bulk entries with an Invalid resolution
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status |
      | 111 | food.com     | food.com      | URI/DOMAIN | NEW    |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |
    And I goto "/escalations/webcat/complaints?f=NEW"
    And I wait for "2" seconds
    And button with id "master-submit" should be disabled
    And I click "#invalid111"
    And I wait for "1" seconds
    And button with id "master-submit" should be enabled
    And I click "#master-submit"
    And I wait for "2" seconds
    And I should see "THE FOLLOWING ENTRIES ARE READY TO BE SUBMITTED"

  @javascript
  Scenario: a user tries to submit bulk entries with an Invalid resolution, but has added a category
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status |
      | 111 | food.com     | food.com      | URI/DOMAIN | NEW    |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |
    And I goto "/escalations/webcat/complaints?f=NEW"
    And I wait for "2" seconds
    And button with id "master-submit" should be disabled
    And I fill in "input_cat_111-selectized" with "Arts" and press enter
    And I wait for "1" seconds
    And I click "#invalid111"
    And I wait for "1" seconds
    And button with id "master-submit" should be enabled
    And I click "#master-submit"
    And I wait for "2" seconds
    And I should see "THE FOLLOWING ENTRIES ARE INCOMPLETE OR INCORRECT"

  @javascript
  Scenario: a user can to submit bulk entries with an Unchanged resolution
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status |
      | 111 | food.com     | food.com      | URI/DOMAIN | NEW    |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |
    And I goto "/escalations/webcat/complaints?f=NEW"
    And I wait for "2" seconds
    And button with id "master-submit" should be disabled
    And I click "#unchanged111"
    And I wait for "1" seconds
    And button with id "master-submit" should be enabled
    And I click "#master-submit"
    And I wait for "2" seconds
    And I should see "THE FOLLOWING ENTRIES ARE READY TO BE SUBMITTED"

  @javascript
  Scenario: a user tries to submit bulk entries with an Unchanged resolution, but has added a category
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status |
      | 111 | food.com     | food.com      | URI/DOMAIN | NEW    |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |
    And I goto "/escalations/webcat/complaints?f=NEW"
    And I wait for "2" seconds
    And button with id "master-submit" should be disabled
    And I fill in "input_cat_111-selectized" with "Arts" and press enter
    And I wait for "1" seconds
    And I click "#unchanged111"
    And I wait for "1" seconds
    And button with id "master-submit" should be enabled
    And I click "#master-submit"
    And I wait for "2" seconds
    And I should see "THE FOLLOWING ENTRIES ARE INCOMPLETE OR INCORRECT"

  @javascript
  Scenario: a user tries to submit bulk entries with an Unchanged resolution, but has added a category
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status |
      | 111 | food.com     | food.com      | URI/DOMAIN | NEW    |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |
    And I goto "/escalations/webcat/complaints?f=NEW"
    And I wait for "2" seconds
    And button with id "master-submit" should be disabled
    And I fill in "input_cat_111-selectized" with "Arts" and press enter
    And I wait for "1" seconds
    And I click "#unchanged111"
    And I wait for "1" seconds
    And button with id "master-submit" should be enabled
    And I click "#master-submit"
    And I wait for "2" seconds
    And I should see "THE FOLLOWING ENTRIES ARE INCOMPLETE OR INCORRECT"

  @javascript
  Scenario: a user tries to submit bulk entries with an Unchanged resolution, but has changed a category
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status |
      | 111 | food.com     | food.com      | URI/DOMAIN | NEW    |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |
    And I goto "/escalations/webcat/complaints?f=NEW"
    And I wait for "2" seconds
    And button with id "master-submit" should be disabled
    And I fill in "input_cat_111-selectized" with "Arts" and press enter
    And I wait for "1" seconds
    And I click "#unchanged111"
    And I wait for "1" seconds
    And button with id "master-submit" should be enabled
    And I click "#master-submit"
    And I wait for "2" seconds
    And I should see "THE FOLLOWING ENTRIES ARE INCOMPLETE OR INCORRECT"


  @javascript
  Scenario: a manager tries to commit bulk PENDING entries
    Given a user with role "webcat manager" exists and is logged in
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status |
      | 111 | food.com     | food.com      | URI/DOMAIN | NEW    |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |
    And I goto "/escalations/webcat/complaints?f=NEW"
    And I wait for "2" seconds
    And button with id "master-submit" should be disabled
    And I fill in "input_cat_111-selectized" with "Arts" and press enter
    And I wait for "1" seconds
    And I click "#unchanged111"
    And I wait for "1" seconds
    And button with id "master-submit" should be enabled
    And I click "#master-submit"
    And I wait for "2" seconds
    And I should see "THE FOLLOWING ENTRIES ARE INCOMPLETE OR INCORRECT"




  # TODO - this does not work in testing env yet - the pop up does not prevent refresh, could be a ff setting
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
  Scenario: a user cannot submit an individual entry with no changes in categories and a Fixed resolution
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status | category                              |
      | 111 | food.com     | food.com      | URI/DOMAIN | NEW    | Health and Medicine, Recipes and Food |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |                                       |
    When I goto "/escalations/webcat/complaints?f=NEW"
    And I wait for "10" seconds
    And I should see "food.com"
    And I should see "blah.com"
    And take a screenshot
    And pending
    And I should see "Health and Medicine"
    And I should see "Recipes and Food"
    And I wait for "3" seconds
    And I click "#submit_changes_111"
    And I wait for "2" seconds


    #TODO - I am unable to get this to work locally, but it passes for Tim
#  @javascript
#  Scenario: a user submits an individual entry with a single removed category and a Fixed resolution


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
  Scenario: a user submits an individual entry that has no existing categories with an Unchanged resolution
    # this can happen if there is not yet enough data for the analyst to classify the url, but its not an invalid ticket
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status |
      | 111 | food.com     | food.com      | URI/DOMAIN | NEW    |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |
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
    And I wait for "3" seconds
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
    And I show all webcat index columns
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
    And I should see "blah.com"
    And I should see "Arts"
    And I should not see "food.com"


  @javascript
  Scenario: a reviewer declines a PENDING entry (and that entry then goes back into ASSIGNED status)
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
    Then I goto "/escalations/webcat/complaints?f=ACTIVE"
    And I wait for "3" seconds
    And I should see "blah.com"
    And I should not see "food.com"
    And I should not see "Arts"



  @javascript
  Scenario: a non-manager can view PENDING entries
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri       | domain    | entry_type | status  | is_important |
      | 111 | food.com  | food.com  | URI/DOMAIN | NEW     |              |
      | 222 | blah.com  | blah.com  | URI/DOMAIN | PENDING |       1      |
    When I goto "/escalations/webcat/complaints"
    And I wait for "3" seconds
    And I click "#filter-complaints"
    And I wait for "1" seconds
    And I click "Waiting for Review"
    And I wait for "5" seconds
    And I should see "blah.com"
    And I should not see "food.com"


  @javascript
  Scenario: a user reopens a completed complaint entry
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      |id| domain            | status    | resolution_comment |
      |1 | blah.com          | COMPLETED | test               |
      |2 | food.com          | COMPLETED | test               |
      |3 | im.hungry.com     | NEW       |                    |
    When I goto "/escalations/webcat/complaints"
    And I wait for "3" seconds
    And I click "#reopen_1"
    And I wait for "5" seconds
    And I click "#advanced-search-button"
    And I fill in selectized of element "#status-input" with "['REOPENED']"
    And I click "#submit-advanced-search"
    And I wait for "4" seconds
    Then the following complaint entry with id: "1" has a status of: "REOPENED"



  ## Hide / Show functionality

  @javascript
  Scenario: a user can show/hide entire columns in the complaints view
    Given a user with role "webcat user" exists and is logged in
    And the following companies exist:
      | id | name                    |
      | 5  | Gilligan's Co.          |
    And the following customers exist:
      | id | name                | company_id | email                    |
      | 12 | Maryanne Summers    |     5      | msummers@islandtours.com |
      | 13 | Ginger Grant        |     5      | ggrant@islandtours.com   |
    And the following platforms exist:
      | id | public_name       | internal_name     | webcat |
      | 1  | TalosIntelligence | TalosIntelligence |   1    |
    And the following complaints exist:
      | id   | description        | customer_id | submitter_type | ticket_source      |
      | 5111 | weather            |      12     | CUSTOMER       | talos-intelligence |
      | 5112 | travel site        |      13     | CUSTOMER       | talos-intelligence |
    And the following complaint entries exist:
      | id   | complaint_id | uri                    | domain                | entry_type | status   | platform_id | suggested_disposition | user_id |
      | 9111 | 5111         | hurricaneshere.com     | hurricaneshere.com    | URI/DOMAIN | ASSIGNED |      1      | News                  |    1    |
      | 9222 | 5112         | tinyhiddenislands.com  | tinyhiddenislands.com | URI/DOMAIN | ASSIGNED |      1      | Travel                |    1    |
    And the following complaint_tags exist:
      | id | name        |
      | 1  | Investigate |
    And I add a complaint_tag of id "1" to complaint of id "5111"
    And I show all webcat index columns
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "3" seconds
    And I should see "9111"
    And I should see "9222"
    And I should see "TI Webform"
    When I click "#webcat-index-table-show-columns-button"
    And I wait for "1" seconds
    And I click "#view-ticket-col-cb"
    And I wait for "1" seconds
    And I should not see "9111"
    And I should not see "9222"
    And I should not see "TI Webform"
    And I click "#view-ticket-col-cb"
    And I wait for "1" seconds
    And I should see "9111"
    And I should see "9222"
    And I should see "TI Webform"
    And I should see "Ginger Grant"
    And I should see "Maryanne Summers"
    And I should see "Gilligan's Co."
    And I should see "msummers@islandtours.com"
    And I should see "ggrant@islandtours.com"
    Then I click "#view-submitter-col-cb"
    And I wait for "1" seconds
    And I should not see "Ginger Grant"
    And I should not see "Maryanne Summers"
    And I should not see "Gilligan's Co."
    And I should not see "msummers@isnlandtours.com"
    And I should not see "ggrant@islandtours.com"
    And I should see "Investigate"
    And I click "#view-tags-col-cb"
    And I wait for "1" seconds
    And I should not see "Investigate"



  @javascript
  Scenario: a user can ensure show/hide column states are saved in the database after a page reload
    Given a user with role "webcat user" exists and is logged in
    And the following companies exist:
      | id | name                    |
      | 5  | Gilligan's Co.          |
    And the following customers exist:
      | id | name                | company_id | email                    |
      | 12 | Maryanne Summers    |     5      | msummers@islandtours.com |
      | 13 | Ginger Grant        |     5      | ggrant@islandtours.com   |
    And the following platforms exist:
      | id | public_name       | internal_name     | webcat |
      | 1  | TalosIntelligence | TalosIntelligence |   1    |
    And the following complaints exist:
      | id   | description        | customer_id | submitter_type | ticket_source      |
      | 5111 | weather            |      12     | CUSTOMER       | talos-intelligence |
      | 5112 | travel site        |      13     | CUSTOMER       | talos-intelligence |
    And the following complaint entries exist:
      | id   | complaint_id | uri                    | domain                | entry_type | status   | platform_id | suggested_disposition | user_id |
      | 9111 | 5111         | hurricaneshere.com     | hurricaneshere.com    | URI/DOMAIN | ASSIGNED |      1      | News                  |    1    |
      | 9222 | 5112         | tinyhiddenislands.com  | tinyhiddenislands.com | URI/DOMAIN | ASSIGNED |      1      | Travel                |    1    |
    And I show all webcat index columns
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "3" seconds
    When I click "#webcat-index-table-show-columns-button"
    And I wait for "1" seconds
    And I should see "Ginger Grant"
    And I should see "Maryanne Summers"
    And I should see "Gilligan's Co."
    And I should see "msummers@islandtours.com"
    And I should see "ggrant@islandtours.com"
    Then I click "#view-submitter-col-cb"
    And I wait for "1" seconds
    And I should not see "Ginger Grant"
    And I should not see "Maryanne Summers"
    And I should not see "Gilligan's Co."
    And I should not see "msummers@isnlandtours.com"
    And I should not see "ggrant@islandtours.com"
    And I refresh the page
    And I wait for "3" seconds
    And I should not see "Ginger Grant"
    And I should not see "Maryanne Summers"
    And I should not see "Gilligan's Co."
    And I should not see "msummers@isnlandtours.com"
    And I should not see "ggrant@islandtours.com"


  ## Editing URIs / submitting updated URIs

  @javascript
    Scenario: a user changes the uri to be categorized to the subdomain using the dropdown tool
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri                                       | subdomain | domain   | path                      | entry_type | status |
      | 111 | vikings.com.au                            | vikings   | com.au   |                           | URI/DOMAIN | NEW    |
      | 222 | flatmates.com.au/login?next=%2Flist-place | flatmates | com.au   | login?next=%2Flist-place  | URI/DOMAIN | NEW    |
      | 333 | food.com                                  |           | food.com |                           | URI/DOMAIN | NEW    |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "3" seconds
    And button with id "quick_edit_uri_111" should be enabled
    And button with id "quick_edit_uri_222" should be enabled
    And button with id "quick_edit_uri_333" should be disabled
    And element with id "edit_uri_input_111" should have content "com.au"
    And I click "#quick_edit_uri_111"
    And I wait for "1" seconds
    And I click ".quick-subdomain"
    And I wait for "1" seconds
    And element with id "edit_uri_input_111" should have content "vikings.com.au"

  @javascript
  Scenario: a user changes the uri to be categorized to the subdomain using the dropdown tool
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri                                       | subdomain | domain   | path                      | entry_type | status |
      | 111 | vikings.com.au                            | vikings   | com.au   |                           | URI/DOMAIN | NEW    |
      | 222 | flatmates.com.au/login?next=%2Flist-place | flatmates | com.au   | login?next=%2Flist-place  | URI/DOMAIN | NEW    |
      | 333 | food.com                                  |           | food.com |                           | URI/DOMAIN | NEW    |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "3" seconds
    And button with id "quick_edit_uri_111" should be enabled
    And button with id "quick_edit_uri_222" should be enabled
    And button with id "quick_edit_uri_333" should be disabled
    And element with id "edit_uri_input_222" should have content "com.au"
    And I click "#quick_edit_uri_222"
    And I wait for "1" seconds
    And I click ".quick-subdomain"
    And I wait for "1" seconds
    And element with id "edit_uri_input_222" should have content "flatmates.com.au"
    And I click "#quick_edit_uri_222"
    And I wait for "1" seconds
    And I click ".quick-uri"
    And I wait for "1" seconds
    And element with id "edit_uri_input_222" should have content "flatmates.com.au/login?next=%2Flist-place"


  @javascript
  Scenario: a user changes the uri to be categorized to the subdomain using the dropdown tool, and submits a Fixed resolution with a category
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri                                       | subdomain | domain   | path                      | entry_type | status |
      | 111 | vikings.com.au                            | vikings   | com.au   |                           | URI/DOMAIN | NEW    |
      | 222 | flatmates.com.au/login?next=%2Flist-place | flatmates | com.au   | login?next=%2Flist-place  | URI/DOMAIN | NEW    |
      | 333 | food.com                                  |           | food.com |                           | URI/DOMAIN | NEW    |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "3" seconds
    And button with id "quick_edit_uri_111" should be enabled
    And button with id "quick_edit_uri_222" should be enabled
    And button with id "quick_edit_uri_333" should be disabled
    And element with id "edit_uri_input_111" should have content "com.au"
    And I click "#quick_edit_uri_111"
    And I wait for "1" seconds
    And I click ".quick-subdomain"
    And I wait for "1" seconds
    And element with id "edit_uri_input_111" should have content "vikings.com.au"
    Then I fill in selectized of element "#input_cat_111" with "['77']"
    And I wait for "1" seconds
    And I click "#submit_changes_111"
    And I wait for "3" seconds
    Then I go to "/escalations/webcat/complaints?f=COMPLETED"
    And I wait for "3" seconds
    And I should see "Alcohol"
    And element with id "edit_uri_input_111" should have content "vikings.com.au"


  @javascript
  Scenario: a user changes the uri to be categorized to the subdomain using the dropdown tool, and bulk submits a Fixed resolution with a category
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri                                       | subdomain | domain   | path                      | entry_type | status |
      | 111 | vikings.com.au                            | vikings   | com.au   |                           | URI/DOMAIN | NEW    |
      | 222 | flatmates.com.au/login?next=%2Flist-place | flatmates | com.au   | login?next=%2Flist-place  | URI/DOMAIN | NEW    |
      | 333 | food.com                                  |           | food.com |                           | URI/DOMAIN | NEW    |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "3" seconds
    And button with id "quick_edit_uri_111" should be enabled
    And button with id "quick_edit_uri_222" should be enabled
    And button with id "quick_edit_uri_333" should be disabled
    And element with id "edit_uri_input_111" should have content "com.au"
    And I click "#quick_edit_uri_111"
    And I wait for "1" seconds
    And I click ".quick-subdomain"
    And I wait for "1" seconds
    And element with id "edit_uri_input_111" should have content "vikings.com.au"
    Then I fill in selectized of element "#input_cat_111" with "['77']"
    And I wait for "1" seconds
    And I click "#master-submit"
    And I wait for "3" seconds
    And I click "#bulk-submit-correct-btn"
    And I wait for "3" seconds
    Then I go to "/escalations/webcat/complaints?f=COMPLETED"
    And I wait for "3" seconds
    And I should see "Alcohol"
    And element with id "edit_uri_input_111" should have content "vikings.com.au"


  #TODO
  # - a user changes the uri to be categorized by editing the text field
  # ^ Each of those testing with submitting a fixed res correctly and incorrectly
  # - a user changes the uri to be submitted to the domain and submits a Fixed resolution with no category



  ## Sorting functionality ###

  @javascript
  Scenario: a user can sort using the Age quicksort button in the toolbar
    Given a user with role "webcat user" exists and is logged in
    And the following platforms exist:
      | id | public_name       | internal_name     | webcat |
      | 1  | TalosIntelligence | TalosIntelligence |   1    |
    And the following complaint entries exist:
      | id   | uri                            | domain                        | entry_type | status   | platform_id | suggested_disposition | user_id | created_at          |
      | 9111 | hurricaneshere.com             | hurricaneshere.com            | URI/DOMAIN | ASSIGNED |      1      | News                  |    1    | 2023-11-01 10:10:10 |
      | 9222 | tinyhiddenislands.com          | tinyhiddenislands.com         | URI/DOMAIN | ASSIGNED |      1      | Travel                |    1    | 2023-12-01 10:10:10 |
      | 9333 | totallysafetours.com           | totallysafetours.com          | URI/DOMAIN | ASSIGNED |      1      | Travel                |    1    | 2024-01-01 10:10:10 |
      | 9444 | howtosurvivebeingstranded.com  | howtosurvivebeingstranded.com | URI/DOMAIN | ASSIGNED |      1      | Travel                |    1    | 2024-01-04 10:10:10 |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "3" seconds
    And pending
#    And row with id x should be in the dom above row with id y?


  #TODO
  ## Sorting the new index
  ## Not sure how to check the order of the rows in testing env

  # - a user can sort using the Age quicksort button in the toolbar
  # - a user can sort using the IP/URI quicksort button in the toolbar
  # - a user can sort by additional criteria in the age dropdown
  # - a users sort preferences should be stored upon page refresh
  # - a user can sort by criteria that are not visible on that page



# Keepting these setups for reference for now
#    And the following companies exist:
#      | id | name                    |
#      | 5  | Gilligan's Co.          |
#      | 7  | Western Investigations  |
#    And the following customers exist:
#      | id | name                | company_id | email                    |
#      | 12 | Maryanne Summers    |     5      | msummers@islandtours.com |
#      | 13 | Ginger Grant        |     5      | ggrant@islandtours.com   |
#      | 14 | Brisco County, Jr.  |     7      | bcjr@wpi.com             |
#      | 15 | Dixie Cousins       |     7      | dxc@wpi.com              |
#    And the following platforms exist:
#      | id | public_name       | internal_name     | webcat |
#      | 1  | TalosIntelligence | TalosIntelligence |   1    |
#    And the following complaints exist:
#      | id   | description        | customer_id | submitter_type | ticket_source      |
#      | 5111 | weather            |      12     | CUSTOMER       | talos-intelligence |
#      | 5112 | travel site        |      13     | CUSTOMER       | talos-intelligence |
#      | 5113 | John Bly owns this |      14     | CUSTOMER       | talos-intelligence |
#      | 5114 | Unknown origin     |      15     | CUSTOMER       | talos-intelligence |
#    And the following complaint entries exist:
#      | id   | complaint_id | uri                    | domain                | entry_type | status   | platform_id | suggested_disposition | user_id |
#      | 9111 | 5111         | hurricaneshere.com     | hurricaneshere.com    | URI/DOMAIN | ASSIGNED |      1      | News                  |    1    |
#      | 9222 | 5112         | tinyhiddenislands.com  | tinyhiddenislands.com | URI/DOMAIN | ASSIGNED |      1      | Travel                |    1    |
#      | 9333 | 5113         | evilmastermind.com     | evilmastermind.com    | URI/DOMAIN | ASSIGNED |      1      | Paranormal            |    1    |
#      | 9444 | 5114         | timetravelingorb.com   | timetravelingorb.com  | URI/DOMAIN | ASSIGNED |      1      | Paranormal            |    1    |
#    And the following complaint_tags exist:
#      | id | name        |
#      | 1  | Investigate |