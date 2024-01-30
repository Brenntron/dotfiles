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


