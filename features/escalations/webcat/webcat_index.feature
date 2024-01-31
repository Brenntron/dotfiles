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
      | id  | uri            | domain          | entry_type | status |
      | 111 | abc.com        | abc.com         | URI/DOMAIN | NEW    |
      | 222 | google.com     | google.com      | URI/DOMAIN | NEW    |

