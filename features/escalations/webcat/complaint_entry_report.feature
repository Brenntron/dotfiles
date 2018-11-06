Feature: Webcat reporting
  In order to generate Complaint entry reports
  I will provide an interface to the complaint entries


  @javascript
  Scenario: Complaints with resolved entries should be displayed
    Given a user with role "webcat user" exists and is logged in
    And the following complaints exist and have entries resolved today:
      | id     |
      | 100    |
      | 101    |
      | 102    |
    And I goto a "complaint_entry" report surrounding the current year
    Then I should see "CUSTOMER NAME"
    Then I should see "URL"
    Then I should see "ENGINEER"
    Then I should see "RESOLUTION"
    Then I should see "FINAL CATEGORY"
    Then I should see "SUGGESTED CATEGORY"
    Then I should see "CREATED"

  @javascript
  Scenario: Exported file should be a csv
    Given a user with role "webcat user" exists and is logged in
    And the following complaints exist and have entries resolved today:
      | id     |
      | 100    |
      | 101    |
      | 102    |
    And I goto a "complaint_entry" report surrounding the current year
    When I click "Export"
    # Note the header isn't `text/csv` *specifically because* we generate this on-the-fly
    Then response header "Content-Type" should be "application/octet-stream"

