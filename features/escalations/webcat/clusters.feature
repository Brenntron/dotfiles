Feature: Webcat clusters
  In order to manage web cat clusters
  I will provide a clusters interface

  Background:
    Given a guest company exists

  @javascript
  Scenario: a user should not see clusters assigned to another users in default view
    Given a user with id "1" has a role "webcat user" and is logged in
    And the following users exist
      |id|
      |2 |
    And WBRS Cluster returns the following stubbed clusters:
      |id|  domain      |
      |1 | food.com     |
      |2 | blah.com     |
      |3 | imhungry.com |
    And the following cluster assignments exists:
      |id| user_id | cluster_id |
      |1 |    1    |     1      |
      |2 |    2    |     3      |
    When I goto "/escalations/webcat/clusters"
    And I wait for "3" seconds
    Then I should see "food.com"
    And I should see "blah.com"
    And I should not see "imhungry.com"

  @javascript
  Scenario: a user should be able to assign cluster
    Given a user with role "webcat user" exists and is logged in
    And WBRS Cluster returns the following stubbed clusters:
      |id|  domain      |
      |1 | food.com     |
      |2 | blah.com     |
      |3 | imhungry.com |
    When I goto "/escalations/webcat/clusters"
    And I wait for "3" seconds
    Then I check "cluster_id_1"
    And I check "cluster_id_2"
    Then I click ".take-ticket-toolbar-button"
    And I wait for "2" seconds
    Then I should see my username in element "#owner_1"
    And I should see my username in element "#owner_2"

  @javascript
  Scenario: a user should be able to unassign cluster
    Given a user with id "1" has a role "webcat user" and is logged in
    And WBRS Cluster returns the following stubbed clusters:
      |id|  domain      |
      |1 | food.com     |
      |2 | blah.com     |
      |3 | imhungry.com |
    And the following cluster assignments exists:
      |id| user_id | cluster_id |
      |1 |    1    |     1      |
      |2 |    1    |     2      |
    When I goto "/escalations/webcat/clusters"
    And I wait for "3" seconds
    Then I should see my username in element "#owner_1"
    And I should see my username in element "#owner_2"
    Then I check "cluster_id_1"
    And I check "cluster_id_2"
    Then I click ".return-ticket-toolbar-button"
    And I wait for "2" seconds
    Then I should not see my username in element "#owner_1"
    And I should not see my username in element "#owner_2"

  @javascript
  Scenario: a user should be able to see "my" clusters
    Given a user with id "1" has a role "webcat user" and is logged in
    And WBRS Cluster returns the following stubbed clusters:
      |id|  domain      |
      |1 | food.com     |
      |2 | blah.com     |
      |3 | imhungry.com |
    And the following cluster assignments exists:
      |id| user_id | cluster_id |
      |1 |    1    |     1      |
      |2 |    1    |     2      |
    When I goto "/escalations/webcat/clusters"
    And I wait for "3" seconds
    Then I click "#filter-clusters"
    And I click link "My Clusters"
    Then I wait for "3" seconds
    Then I should see "food.com"
    And I should see "blah.com"
    And I should not see "imhungry.com"

  @javascript
  Scenario: a user should be able to see "unassigned" clusters
    Given a user with id "1" has a role "webcat user" and is logged in
    And WBRS Cluster returns the following stubbed clusters:
      |id|  domain      |
      |1 | food.com     |
      |2 | blah.com     |
      |3 | imhungry.com |
    And the following cluster assignments exists:
      |id| user_id | cluster_id |
      |1 |    1    |     1      |
      |2 |    1    |     2      |
    When I goto "/escalations/webcat/clusters"
    And I wait for "3" seconds
    Then I click "#filter-clusters"
    And I click link "Unassigned Clusters"
    Then I wait for "3" seconds
    Then I should not see "food.com"
    And I should not see "blah.com"
    And I should see "imhungry.com"

  @javascript
  Scenario: a user should be able to see "all" clusters
    Given a user with id "1" has a role "webcat user" and is logged in
    And WBRS Cluster returns the following stubbed clusters:
      |id|  domain      |
      |1 | food.com     |
      |2 | blah.com     |
      |3 | imhungry.com |
    And the following cluster assignments exists:
      |id| user_id | cluster_id |
      |1 |    1    |     1      |
      |2 |    1    |     2      |
    When I goto "/escalations/webcat/clusters"
    And I wait for "3" seconds
    Then I click "#filter-clusters"
    And I click link "All Clusters"
    Then I wait for "3" seconds
    Then I should see "food.com"
    And I should see "blah.com"
    And I should see "imhungry.com"
