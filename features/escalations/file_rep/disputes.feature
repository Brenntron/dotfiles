Feature: Disputes
  In order to interact with FileRep disputes
  as a user
  I will provide ways to interact with disputes

  @javascript
  Scenario: an analyst tries to create a FileRep ticket
    Given a user with role "filerep user" exists and is logged in
    And I go to "/escalations/file_rep/disputes"
    Then I click "#new-dispute"
    Then I fill in "file-rep-shas" with "343518b26e0a872772808605f9f28aa75f64d86a6608e1347c979d033a72cb54"
    Then I click ".primary"
    Then a FileRep Ticket should have been created

  @javascript
  Scenario: a user tries to visit the FileRep disputes page without a FileRep role
    Given a user with role "other user" exists and is logged in
    And I go to "/escalations/file_rep/disputes"
    Then I should see "You are not authorized"

  @javascript
  Scenario: a user tries to visit the FileRep disputes page with a FileRep role
    Given a user with role "filerep user" exists and is logged in
    And I go to "/escalations/file_rep/disputes"
    Then I should see "File Reputation Tickets"

  @javascript
  Scenario: a user tries checks the left navigation panel without a FileRep role
    Given a user with role "webrep user" exists and is logged in
    Then I go to "/"
    And I click on element "img" with alt "Menu"
    And I click on element "img" with alt "Escalations"
    Then I wait for "1" seconds
    Then I should not see "FILE REPUTATION"
    Then I should see "WEB REPUTATION"

  @javascript
  Scenario: a user tries checks the left navigation panel with a FileRep role
    Given a user with role "filerep user" exists and is logged in
    Then I go to "/"
    And I click on element "img" with alt "Menu"
    And I click on element "img" with alt "Escalations"
    Then I wait for "1" seconds
    Then I should see "FILE REPUTATION"
    Then I should not see "WEB REPUTATION"

  @javascript
  Scenario: a user visits the FileRep disputes index page and sees all elements of the intended layout
    Given a user with role "filerep user" exists and is logged in
    And I go to "/escalations/file_rep/disputes"
    Then I should see "STATUS"
    Then I should see "FILE NAME"
    Then I should see "SHA256"
    Then I should see "FILE SIZE"
    Then I should see "SAMPLE TYPE"
    Then I should see "AMP Disp"
    Then I should see "IN ZOO"
    Then I should see "REVERSING LABS"
    Then I should see "CUSTOMER ORGANIZATION"
    Then I should see "ASSIGNEE"

  @javascript
  Scenario: a disables the File Name column from the FileRep disputes index page
    Given a user with role "filerep user" exists and is logged in
    And I go to "/escalations/file_rep/disputes"
    When I click "#file-index-table-show-columns-button"
    And I click "#file-name-checkbox"
    Then I should not see "FILE NAME"

  @javascript
  Scenario: a enables the Resolution column from the FileRep disputes index page
    Given a user with role "filerep user" exists and is logged in
    And I go to "/escalations/file_rep/disputes"
    When I click "#file-index-table-show-columns-button"
    And I click "#resolution-checkbox"
    Then I should see "RESOLUTION"