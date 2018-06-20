Feature: Org Subset management
  In order to access and minipulate org subsets
  as an admin user
  I will provide a way to interact with org subsets

  Scenario: an admin can create a subset
    Given an admin user with role "analyst" exists and is logged in
    When I goto "/admin/org_subsets/new"
    And I fill in "org_subset[name]" with "webcat"
    When I click "Save"
    And I wait for "2" seconds
    Then I should see "webcat"

  Scenario: an admin can edit a subset


  Scenario: an admin can delete a subset
