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
#    TODO: Figure out a way not to hard-code the dates below
    And I goto "/escalations/webcat/reports/complaint_entry?utf8=1&report%5Bdate_from%5D=2000-01-01&report%5Bdate_to%5D=3999-01-01&report%5Bcustomer_name%5D=&commit=Report"
    Then I should see "CUSTOMER NAME"
    Then I should see "URL"
    Then I should see "ENGINEER"
    Then I should see "RESOLUTION"
    Then I should see "FINAL CATEGORY"
    Then I should see "SUGGESTED CATEGORY"
    Then I should see "CREATED"
    Then take a photo