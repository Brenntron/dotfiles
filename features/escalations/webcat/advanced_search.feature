Feature: WebCat Advanced Search

  @javascript
  Scenario: I perform an advanced search on status and resolution fields simultaneously
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
  Scenario: I perform an advanced search on company name
    Given a user with role "webcat user" exists and is logged in
    Given the following complaints exist:
      | id | customer_id |
      | 1  | 1           |
      | 2  | 2           |
      | 3  |             |
      | 4  |             |
    Given the following complaint entries exist:
      | id | resolution | status    | complaint_id |
      | 1  | FIXED      | PENDING   | 1            |
      | 2  | DUPLICATE  | COMPLETED | 2            |
      | 3  | FIXED      | PENDING   | 3            |
      | 4  | DUPLICATE  | COMPLETED | 4            |
    Given the following customers exist:
      | id | company_id | email             |
      | 1  | 22         |  tokyo@gmail.com  |
      | 2  | 33         |  boston@gmail.com |
    Given the following companies exist:
      | id  | name          |
      | 22  | Bobby Burgers |
      | 33  | Pizza Dojo    |
    When I go to "/escalations/webcat/complaints"
    And I click "#advanced-search-button"
    And I click "#add-search-items-button"
    And I click "#company-cb"
    And I click "#resolution-cb"
    And I click "#add-search-criteria"
    And I fill in selectized of element "#resolution-input" with "['FIXED','DUPLICATE']"
    And I fill in selectized of element "#company-input" with "['Bobby Burgers','Pizza Dojo']"
    And I fill in selectized of element "#status-input" with "['PENDING','COMPLETED']"
    And I click "#submit-advanced-search"
    And I wait for "4" seconds
    Then I should see tr element with id "1"
    Then I should see tr element with id "2"
    Then I should not see tr element with id "3"
    Then I should not see tr element with id "4"

  @javascript
  Scenario: I perform an advanced search on customer name
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
    And I click "#advanced-search-button"
    And I click "#add-search-items-button"
    And I click "#name-cb"
    And I click "#resolution-cb"
    And I click "#add-search-criteria"
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
  Scenario: I perform an advanced search on tags
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
    And I click "#add-search-criteria"
    And I fill in selectized of element "#resolution-input" with "['FIXED','DUPLICATE']"
    And I fill in selectized of element "#tags-input" with "['Slytherin','Hufflepuff']"
    And I fill in selectized of element "#status-input" with "['PENDING','COMPLETED']"
    And I click "#submit-advanced-search"
    And I wait for "4" seconds
    Then I should see tr element with id "1"
    Then I should see tr element with id "4"
    Then I should not see tr element with id "3"
    Then I should not see tr element with id "4"