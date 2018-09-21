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

  @javascript
  Scenario: A user must review a high telemetry site
    Given a user with role "admin" exists and is logged in
    And a complaint entry with trait "important" exists
    And I goto "/escalations/webcat"
    And I should see "bogus_category"
    Then I should not see "Update"
    When I click button with class "expand-row-button-inline"
    And I choose "fixed1"
    And I should see "Update"
    And I should not see "commit"
    When I click "Update"
    Then I should see "commit"

  @javascript
  Scenario: A user does not need to review a low telemetry site
    Given a user with role "admin" exists and is logged in
    And a complaint entry with trait "not_important" exists
    And I goto "/escalations/webcat"
    And I should see "bogus_category"
    Then I should not see "Update"
    When I click button with class "expand-row-button-inline"
    And I choose "fixed1"
    And I should see "Update"
    And I should not see "commit"
    When I click "Update"
    Then I should not see "commit"

  @javascript
  Scenario: a user can take a complaint
    Given a user with role "webcat user" exists and is logged in
    And a new complaint entry with trait "not_important" exists
    And I goto "/escalations/webcat"
    And I wait for "2" seconds
    And I should see "Vrt Incoming"
    And I click a table row
    And I click button "Take selected"
    Then I should see "ASSIGNED"
    Then take a photo
    And I should not see "Vrt Incoming"

  @javascript
  Scenario: a user can return a complaint
    Given a user with role "webcat user" exists and is logged in
    And an assigned complaint entry with trait "not_important" exists
    And I goto "/escalations/webcat"
    And I wait for "1" seconds
    And I should not see "Vrt Incoming"
    And I click a table row
    And I click button "Return selected"
    And I wait for "1" seconds
    Then I should see "Vrt Incoming"

  @javascript
  Scenario: a user attempts to submit changes without categories and receives expected error alert
    Given a user with role "webcat user" exists and is logged in
    And a complaint entry with trait "new_entry" exists
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I wait for "2" seconds
    And I click ".expand-all"
    And I wait for "2" seconds
    And I click "#submit_changes_1"
    And I wait for "2" seconds
    Then I should see "MUST INCLUDE AT LEAST ONE CATEGORY."

  @javascript
  Scenario: a user visits a complaint show page and sees its IP
    Given a user with role "webcat user" exists and is logged in
    And a complaint entry with trait "empty_domain" exists
    And I goto "/escalations/webcat/complaints/1"
    Then I should see "1.1.1.1"

