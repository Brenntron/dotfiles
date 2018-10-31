Feature: Webcat reporting
  In order to generate Engineering reports
  I will provide an interface to view complaint stats


  @javascript
  Scenario: Complaints with resolved entries should be displayed
    Given a user with role "webcat user" exists and is logged in
    And the following complaints exist and have entries resolved today:
      | id     |
      | 100    |
      | 101    |
      | 102    |
#    TODO: Figure out a way not to hard-code the dates below
    And I goto "/escalations/webcat/reports/resolution?utf8=1&report%5Bdate_from%5D=2000-01-01&report%5Bdate_to%5D=3999-01-01&commit=Report"
    Then I should see "FIXED COMPLAINTS"
    Then I should see "INVALID COMPLAINTS"
    Then I should see "UNCHANGED COMPLAINTS"
    Then I should see "DUPLICATE COMPLAINTS"
    Then I should see "ENG AVE"
    Then I should see "ENG MAX"
    Then I should see "DEPT AVE"
    Then I should see "DEPT MAX"
