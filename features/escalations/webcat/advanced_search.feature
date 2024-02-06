Feature: WebCat Advanced Search



  @javascript
  Scenario: a user performs an advanced search on status and resolution fields simultaneously
    Given a user with role "webcat user" exists and is logged in
    Given the following complaint entries exist:
      | id | resolution | status    |
      | 1  | FIXED      | PENDING   |
      | 2  | DUPLICATE  | COMPLETED |
      | 3  | UNCHANGED  | NEW       |
      | 4  | FIXED      | NEW       |
    When I go to "/escalations/webcat/complaints"
    And I click "#advanced-search-button"
    And I fill in selectized of element "#resolution-input" with "['FIXED','DUPLICATE']"
    And I fill in selectized of element "#status-input" with "['PENDING','COMPLETED']"
    And I click "#submit-advanced-search"
    And I wait for "4" seconds
    Then I should see tr element with id "1"
    Then I should see tr element with id "2"
    Then I should not see tr element with id "3"
    Then I should not see tr element with id "4"


  @javascript
  Scenario: a user performs an advanced search on company name
    Given a user with role "webcat user" exists and is logged in
    Given the following companies exist:
      | id  | name          |
      | 11  | Not a Guest   |
      | 22  | Bobby Burgers |
      | 33  | Pizza Dojo    |
    Given the following customers exist:
      | id   | company_id | email             | name        |
      | 100  | 22         |  tokyo@gmail.com  | Tokyo Drift |
      | 102  | 33         |  boston@gmail.com | Pippa Mann  |
    Given the following complaints exist:
      | id    | customer_id  |
      | 1001  | 100          |
      | 1002  | 102          |
    And the following complaint entries exist:
      | id  | uri          | domain        | entry_type | status | complaint_id |
      | 111 | bestbobs.com | bestbobs.com  | URI/DOMAIN | NEW    |      1001    |
      | 222 | blah.com     | blah.com      | URI/DOMAIN | NEW    |      1002    |
    When I go to "/escalations/webcat/complaints"
    And I wait for "5" seconds
#    And take a screenshot
    And I click "#advanced-search-button"
    And I click "#add-search-items-button"
    And I click "#resolution-cb"
    And I click "#cancel-add-criteria"
    And I fill in selectized of element "#company-input" with "['Bobby Burgers']"
    And I click "#submit-advanced-search"
    And I wait for "8" seconds
    Then I should see tr element with id "1"
    Then I should see tr element with id "2"
    Then I should not see tr element with id "3"
    Then I should not see tr element with id "4"


  @javascript
  Scenario: a user performs an advanced search on customer name
    Given a user with role "webcat user" exists and is logged in
    Given the following complaints exist:
      | id | customer_id |
      | 1  | 1           |
      | 2  | 2           |
      | 3  | 3           |
      | 4  | 4           |
    Given the following complaint entries exist:
      | id | resolution | status    | complaint_id |
      | 1  | FIXED      | PENDING   | 1            |
      | 2  | DUPLICATE  | COMPLETED | 2            |
      | 3  | FIXED      | PENDING   | 3            |
      | 4  | DUPLICATE  | COMPLETED | 4            |
    Given the following customers exist:
      | id | name          | email                  |
      | 1  | Bilbo Baggins | avarice@gold.com       |
      | 2  | Draco Malfoy  | slytherin@hogwarts.com |
      | 3  | Eric Cartman  | southpark@denver.com   |
      | 4  | Thor          | asgard@marvel.com      |
    When I go to "/escalations/webcat/complaints"
    And I wait for "4" seconds
    And take a screenshot
    And I click "#advanced-search-button"
    And I click "#add-search-items-button"
    And I click "#name-cb"
    And I click "#resolution-cb"
    And I click "#cancel-add-criteria"
    And I fill in selectized of element "#resolution-input" with "['FIXED','DUPLICATE']"
    And I fill in selectized of element "#name-input" with "['Draco Malfoy','Bilbo Baggins']"
    And I fill in selectized of element "#status-input" with "['PENDING','COMPLETED']"
    And I click "#submit-advanced-search"
    And I wait for "4" seconds
    Then I should see tr element with id "1"
    Then I should see tr element with id "2"
    Then I should not see tr element with id "3"
    Then I should not see tr element with id "4"


  @javascript
  Scenario: a user performs an advanced search on tags
    Given a user with role "webcat user" exists and is logged in
    Given the following complaints exist:
      | id | customer_id |
      | 1  | 1           |
      | 2  | 2           |
      | 3  | 3           |
      | 4  | 4           |
    Given the following complaint entries exist:
      | id | resolution | status    | complaint_id |
      | 1  | FIXED      | PENDING   | 1            |
      | 2  | DUPLICATE  | COMPLETED | 2            |
      | 3  | FIXED      | PENDING   | 3            |
      | 4  | DUPLICATE  | COMPLETED | 4            |
    Given the following complaint_tags exist:
      | id | name       |
      | 1  | Slytherin  |
      | 2  | Gryffindor |
      | 3  | Ravenclaw  |
      | 4  | Hufflepuff |
    Given I add a complaint_tag of id "1" to complaint of id "1"
    Given I add a complaint_tag of id "2" to complaint of id "2"
    Given I add a complaint_tag of id "3" to complaint of id "3"
    Given I add a complaint_tag of id "4" to complaint of id "4"
    When I go to "/escalations/webcat/complaints"
    And I click "#advanced-search-button"
    And I click "#add-search-items-button"
    And I click "#name-cb"
    And I click "#resolution-cb"
    And I click "#cancel-add-criteria"
    And I fill in selectized of element "#resolution-input" with "['FIXED','DUPLICATE']"
    And I fill in selectized of element "#tags-input" with "['Slytherin','Hufflepuff']"
    And I fill in selectized of element "#status-input" with "['PENDING','COMPLETED']"
    And I click "#submit-advanced-search"
    And I wait for "4" seconds
    Then I should see tr element with id "1"
    Then I should see tr element with id "4"
    Then I should not see tr element with id "2"
    Then I should not see tr element with id "3"


  @javascript
  Scenario: a user performs an advanced search on assignee
    Given a user with role "webcat user" exists and is logged in
    Given the following complaints exist:
      | id | customer_id |
      | 1  | 1           |
      | 2  | 2           |
      | 3  | 3           |
      | 4  | 4           |
    Given the following complaint entries exist:
      | id | resolution | status    | complaint_id | user_id |
      | 1  | FIXED      | PENDING   | 1            | 1      |
      | 2  | DUPLICATE  | COMPLETED | 2            | 11      |
      | 3  | FIXED      | PENDING   | 3            | 22      |
      | 4  | DUPLICATE  | COMPLETED | 4            | 2      |
    Given the following users exist
      | id | cvs_username  | display_name |
      | 11  | hpotter       | Harry Potter |
      | 22  | rweasle       | Ron Weasley  |
    When I go to "/escalations/webcat/complaints"
    And I click "#advanced-search-button"
    And I click "#add-search-items-button"
    And I click "#assignee-cb"
    And I click "#resolution-cb"
    And I click "#cancel-add-criteria"
    And I fill in selectized of element "#resolution-input" with "['FIXED','DUPLICATE']"
    And I fill in selectized of element "#assignee-input" with "['hpotter','rweasle']"
    And I fill in selectized of element "#status-input" with "['PENDING','COMPLETED']"
    And I click "#submit-advanced-search"
    And I wait for "10" seconds
    Then I should see tr element with id "2"
    Then I should see tr element with id "3"
    Then I should not see tr element with id "1"
    Then I should not see tr element with id "4"

  @javascript
  Scenario: a user performs an advanced search on platform
    Given a user with role "webcat user" exists and is logged in
    And platforms with all traits exist
    Given the following complaints exist:
      | id | customer_id | platform_id |
      | 1  | 1           |  1          |
      | 2  | 2           |  2          |
      | 3  | 3           |             |
    Given the following complaint entries exist:
      | id | resolution | status    | complaint_id | user_id | platform_id |
      | 1  | FIXED      | PENDING   | 1            | 1       |             |
      | 2  | DUPLICATE  | COMPLETED | 2            | 11      |             |
      | 3  | FIXED      | PENDING   | 3            | 22      | 4           |
    Given the following users exist
      | id | cvs_username  | display_name |
      | 11  | hpotter       | Harry Potter |
      | 22  | rweasle       | Ron Weasley  |
    When I go to "/escalations/webcat/complaints"
    And I click "#advanced-search-button"
    And I click "#add-search-items-button"
    And I click "#platform-cb"
    And I click "#cancel-add-criteria"
    And I wait for "5" seconds
    And I fill in selectized of element "#platform-input" with "['1','4']"
    And I click "#submit-advanced-search"
    Then I should see "PLATFORMS: All, Webcat"
    Then I should see tr element with id "1"
    Then I should see tr element with id "3"
    Then I should not see tr element with id "2"


  @javascript
  Scenario: a user changes the fields they want displayed in the advanced search and those are maintained
    Given a user with role "webcat user" exists and is logged in
    When I go to "/escalations/webcat/complaints"
    And  I click "#advanced-search-button"
    Then I should see "Complaint (URL/IP/Domain)"
    And  I should see "Added Through Channel"
    And  I should not see "Customer Name"
    And  I click "#remove-criteria-complaint"
    And  I should not see "Complaint (URL/IP/Domain)"
    And  I click "#remove-criteria-channel"
    And  I should not see "Added Through Channel"
    And  I click "#add-search-items-button"
    And  I click "#name-cb"
    And  I should see "Customer Name"
    And  I go to "/escalations/webcat/complaints"
    And  I click "#advanced-search-button"
    And  I should not see "Complaint (URL/IP/Domain)"
    And  I should not see "Added Through Channel"
    And  I should see "Customer Name"
