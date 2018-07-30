Feature: Webcat complaints
  In order to manage web cat complaints
  I will provide a complaints interface

  #TODO: we need to update the user role on these tests

  @javascript
  Scenario: a user can manually create a new complaint
    Given a user with role "admin" exists and is logged in
    And the following companies exist:
    |id| name  |
    | 1| Cisco |
    And the following customers exist:
    | company_id | name         | email           |
    | 1          | Talos Person | talos@cisco.com |
    And I goto "/escalations/webcat"
    And I click "new-complaint"
    And I fill in "ips_urls" with "talosintelligence.com"
    And I fill in "description" with "This is my favorite website"
    And I fill in "customers" with "Cisco:Talos Person:talos@cisco.com"
    And I fill in selectized with "urgent"
    And I click "Create"
    And I click button "Create"
    And I wait for "3" seconds
    And I should see "COMPLAINT CREATED"
