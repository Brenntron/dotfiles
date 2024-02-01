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


  # TODO - this does not work in testing env yet
  # might need tweaks to testing browser
#  @javascript
#  Scenario: a user sees a pop-up window if they make changes to an entry but do not submit
#    Given a user with role "webcat user" exists and is logged in
#    And the following complaint entries exist:
#      | id  | uri          | domain        | entry_type | status |
#      | 111 | food.com     | food.com      | URI/DOMAIN | NEW    |
#      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |
#    And I goto "/escalations/webcat/complaints?f=NEW"
#    And I wait for "2" seconds
#    And I fill in "input_cat_111-selectized" with "Arts" and press enter
#    And I refresh the page
#    And I wait for "3" seconds
#    And take a screenshot