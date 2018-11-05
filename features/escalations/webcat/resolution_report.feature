Feature: Webcat reporting
  In order to generate Engineering reports
  I will provide an interface to view complaint stats


  @javascript
  Scenario: Engineering reports should be accessible
    Given a user with role "webcat user" exists and is logged in
    And the following complaints exist and have entries resolved today:
      | id     |
      | 100    |
      | 101    |
      | 102    |
    And I goto a "resolution" report surrounding the current year
    Then I should see "FIXED COMPLAINTS"
    Then I should see "INVALID COMPLAINTS"
    Then I should see "UNCHANGED COMPLAINTS"
    Then I should see "DUPLICATE COMPLAINTS"
    Then I should see "ENG AVE"
    Then I should see "ENG MAX"
    Then I should see "DEPT AVE"
    Then I should see "DEPT MAX"

  @javascript
  Scenario: Exported file should be a csv
    Given a user with role "webcat user" exists and is logged in
    And the following complaints exist and have entries resolved today:
      | id     |
      | 100    |
      | 101    |
      | 102    |
    And I goto a "resolution" report surrounding the current year
    When I click "Export"
    # Note the header isn't `text/csv` *specifically because* we generate this on-the-fly
    Then response header "Content-Type" should be "application/octet-stream"

