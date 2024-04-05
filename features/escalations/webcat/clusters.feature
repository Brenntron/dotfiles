Feature: Webcat clusters
  In order to manage web cat clusters
  I will provide a clusters interface

  Background:
    Given a guest company exists
    And Beaker Verdicts is stubbed with some response
    And WBRS Category is stubbed with some response
    And WBRS Cluster processing is stubbed with some response
    And WBRS TopUrl API call is stubbed with:
      |   url   | is_important |
      | food.com|     true     |
      | blah.com|     false    |
    And WBRS Cluster returns the following stubbed clusters:
      |id|  domain      | global_volume |
      |1 | food.com     |       1       |
      |3 | imhungry.com |       3       |
    And the following ngfw clusters exist:
      | id |  domain  | traffic_hits |
      | 1  | blah.com |      2       |

  @javascript
  Scenario: a user should not see clusters assigned to another users in default view
    Given a user with id "1" has a role "webcat user" and is logged in
    And the following users exist
      |id|
      |2 |
    And the following cluster assignments exists:
      |id| user_id |    domain    |
      |1 |    1    | food.com     |
      |2 |    2    | imhungry.com |
    When I goto "/escalations/webcat/clusters"
    And I wait for "3" seconds
    Then I should see "Current Clusters"
    Then I should see "food.com"
    And I should see "blah.com"
    And I should not see "imhungry.com"

  @javascript
  Scenario: a user should be able to assign cluster
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/clusters"
    Then I check "cluster_row_0"
    And I check "cluster_row_1"
    Then I click ".take-ticket-toolbar-button"
    Then I should see my username in element "#owner_food_com"
    And I should see my username in element "#owner_blah_com"

  @javascript
  Scenario: a user should be able to unassign cluster
    Given a user with id "1" has a role "webcat user" and is logged in
    And the following cluster assignments exists:
      |id| user_id |  domain  |
      |1 |    1    | food.com |
      |2 |    1    | blah.com |
    When I goto "/escalations/webcat/clusters"
    Then I should see my username in element "#owner_food_com"
    And I should see my username in element "#owner_blah_com"
    Then I check "cluster_row_0"
    And I check "cluster_row_1"
    Then I click ".return-ticket-toolbar-button"
    Then I should not see my username in element "#owner_food_com"
    And I should not see my username in element "#owner_blah_com"

  @javascript
  Scenario: a user should be able to see "my" clusters
    Given a user with id "1" has a role "webcat user" and is logged in
    And the following cluster assignments exists:
      |id| user_id |  domain  |
      |1 |    1    | food.com |
      |2 |    1    | blah.com |
    When I goto "/escalations/webcat/clusters"
    Then I click "#filter-clusters"
    And I click link "My Clusters"
    Then I wait for "3" seconds
    Then I should see "My Clusters"
    Then I should see "food.com"
    And I should see "blah.com"
    And I should not see "imhungry.com"

  @javascript
  Scenario: a user should be able to see "unassigned" clusters
    Given a user with id "1" has a role "webcat user" and is logged in
    And the following cluster assignments exists:
      |id| user_id |  domain  |
      |1 |    1    | food.com |
      |2 |    1    | blah.com |
    When I goto "/escalations/webcat/clusters"
    Then I click "#filter-clusters"
    And I click link "Unassigned Clusters"
    Then I wait for "3" seconds
    And I should see "Unassigned Clusters"
    Then I should not see "food.com"
    And I should not see "blah.com"
    And I should see "imhungry.com"

  @javascript
  Scenario: a user should be able to see "all" clusters
    Given a user with id "1" has a role "webcat user" and is logged in
    And the following cluster assignments exists:
      |id| user_id |  domain  |
      |1 |    1    | food.com |
      |2 |    1    | blah.com |
    When I goto "/escalations/webcat/clusters"
    Then I click "#filter-clusters"
    And I click link "All Clusters"
    Then I wait for "3" seconds
    And I should see "All Clusters"
    Then I should see "food.com"
    And I should see "blah.com"
    And I should see "imhungry.com"

  @javascript
  Scenario: user should see important label if there is important clusters
    Given a user with id "1" has a role "webcat user" and is logged in
    And the following cluster assignments exists:
      |id| user_id |  domain  |
      |1 |    1    | food.com |
      |2 |    1    | blah.com |
    When I goto "/escalations/webcat/clusters"
    And I should see element ".is-important"


  @javascript
  Scenario: user should not see important label if there are no important clusters
    Given a user with id "1" has a role "webcat user" and is logged in
    And WBRS TopUrl API call is stubbed with:
      |   url   | is_important |
      | food.com|     false    |
      | blah.com|     false    |
    And the following cluster assignments exists:
      |id| user_id |  domain  |
      |1 |    1    | food.com |
      |2 |    1    | blah.com |
    When I goto "/escalations/webcat/clusters"
    And I should not see element ".is-important"

  @javascript
  Scenario: an important cluster should go to 2nd person review after categorization
    Given a user with id "1" has a role "webcat user" and is logged in
    When I goto "/escalations/webcat/clusters"
    Then I check "cluster_row_2"
    And I fill in selectized of element "#food_com_categories" with "[6]"
    Then I click "Submit Changes"
    Then I should see button with class "cluster-submit-button"
    And I should see button with class "cluster-cancel-button"

  @javascript
  Scenario: a user should be able to see "waiting for review" clusters
    Given a user with id "1" has a role "webcat user" and is logged in
    When I goto "/escalations/webcat/clusters"
    Then I check "cluster_row_2"
    And I fill in selectized of element "#food_com_categories" with "[6]"
    Then I click "Submit Changes"
    Then I click "#filter-clusters"
    And I click link "Waiting For Review"
    Then I wait for "3" seconds
    Then I should see "Pending Clusters"
    Then I should see "food.com"
    And I should not see "blah.com"

  @javascript
  Scenario: user can decline cluster categorization on 2nd person review
    Given a user with id "1" has a role "webcat user" and is logged in
    And the following cluster assignments exists:
      |id| user_id |  domain  |
      |1 |    1    | food.com |
      |2 |    1    | blah.com |
    When I goto "/escalations/webcat/clusters"
    Then I check "cluster_row_2"
    And I fill in selectized of element "#food_com_categories" with "[6]"
    Then I click "Submit Changes"
    Then I click button with class "cluster-cancel-button"
    And I wait for "1" seconds
    Then I should see "CLUSTER CATEGORIES WERE DECLINED."
    And I click "#msg-modal"
    Then I should not see button with class "cluster-submit-button"
    And I should not see button with class "cluster-cancel-button"

  @javascript
  Scenario: cluster should be assigned to the user who declined categorization
    Given a user with id "1" has a role "webcat user" and is logged in
    And the following cluster assignments exists:
      |id| user_id |  domain  |
      |1 |    1    | food.com |
      |2 |    1    | blah.com |
    When I goto "/escalations/webcat/clusters"
    Then I check "cluster_row_2"
    And I fill in selectized of element "#food_com_categories" with "[6]"
    Then I click "Submit Changes"
    Then I click button with class "cluster-cancel-button"
    And I wait for "1" seconds
    Then I should see "CLUSTER CATEGORIES WERE DECLINED."
    And I click "#msg-modal"
    Then I should see my username in element "#owner_food_com"

  @javascript
  Scenario: non important complaints should be submitted without 2nd person review
    Given a user with id "1" has a role "webcat user" and is logged in
    And the following cluster assignments exists:
      |id| user_id |  domain  |
      |1 |    1    | food.com |
      |2 |    1    | blah.com |
    When I goto "/escalations/webcat/clusters"
    Then I check "cluster_row_1"
    And I fill in selectized of element "#blah_com_categories" with "[6]"
    Then I click "Submit Changes"
    Then I should not see button with class "cluster-submit-button"
    And I should not see button with class "cluster-cancel-button"

  @javascript
  Scenario: a cluster should go to 3rd person review
    Given a user with id "1" has a role "webcat user" and is logged in
    And the following users exist
      | id | cvs_username | display_name |
      | 2  | admatter     | Adam Mattern |
    And WBRS Cluster returns the following stubbed clusters:
      |id|  domain      |
      |1 | food.com     |
      |2 | blah.com     |
      |3 | 127.0.0.1    |
    And GuardRails verdicts API is stubbed to return failure for domain "food.com"
    And the following cluster categorizations exist:
      |id|  cluster_id  | category_ids  | user_id |
      |1 |      1       |    [6, 77]    |    1    |
    When I goto "/escalations/webcat/clusters?f=pending"
    And I wait for "3" seconds
    And I should see "food.com"
    Then I click button with class "cluster-submit-button"
    And I wait for "10" seconds
    Then I should see "Cluster should pass manager review"
    Then I click "#msg-modal"
    And I goto "/escalations/webcat/clusters?f=pending"
    And I should see "food.com"
    Then I should see content "admatter" within "#owner_food_com"

  @javascript
  Scenario: webcat manager should be able to submit cluster without 3rd person review
    Given a webcat manager with id "1" exists and is logged in
    And WBRS Cluster returns the following stubbed clusters:
      |id|  domain      |
      |1 | food.com     |
      |2 | blah.com     |
      |3 | 127.0.0.1    |
    And GuardRails verdicts API is stubbed to return failure for domain "food.com"
    And the following cluster categorizations exist:
      |id|  cluster_id  | category_ids  | user_id |
      |1 |      1       |    [6, 77]    |    1    |
    When I goto "/escalations/webcat/clusters?f=pending"
    And I wait for "3" seconds
    And I should see "food.com"
    Then I click button with class "cluster-submit-button"
    And I wait for "10" seconds
    Then I should see "CLUSTER WAS SUBMITTED."
    Then I click "#msg-modal"
    And I goto "/escalations/webcat/clusters?f=pending"
    And I wait for "3" seconds
    And I should not see "food.com"

  @javascript
  Scenario: user should be able to filter clusters by platform
    Given a user with id "1" has a role "webcat user" and is logged in
    When I goto "/escalations/webcat/clusters"
    And I should see "food.com"
    And I should see "blah.com"
    Then I select "WSA" from "webcat-platform-filter"
    And I should see "food.com"
    And I should not see "blah.com"
    Then I select "NGFW" from "webcat-platform-filter"
    And I should not see "food.com"
    And I should see "blah.com"
    Then I select "All" from "webcat-platform-filter"
    And I should see "food.com"
    And I should see "blah.com"

  @javascript
  # this Scenario uses NGFW clusters only to not bring the extra complexity
  # by stubbing WBNP data depends on selected filter type
  # because we don't filter data on our side - RuleAPI does that for us
  Scenario: user should be able to filter clusters by cluster type
    Given a user with id "1" has a role "webcat user" and is logged in
    And the following ngfw clusters exist:
      | id |  domain     |
      | 1  | example.com |
      | 1  | 127.0.0.1   |
    When I goto "/escalations/webcat/clusters"
    And I should see "example.com"
    And I should see "127.0.0.1"
    Then I select "Domains" from "webcat-cluster-type-filter"
    And I should see "example.com"
    And I should not see "127.0.0.1"
    Then I select "IP addresses" from "webcat-cluster-type-filter"
    And I wait for "20" seconds
    And I should not see "example.com"
    And I should see "127.0.0.1"
    Then I select "All" from "webcat-cluster-type-filter"
    And I should see "example.com"
    And I should see "127.0.0.1"

  Rule: domain names (not ip addresses) can display whois information
    @javascript
    Scenario: user should be able to see whois info for domains
      Given a user with id "1" has a role "webcat user" and is logged in
      When I goto "/escalations/webcat/clusters"
      Then I should see "imhungry.com"
      When I click first element of class ".whois-btn"
      And I wait for the ajax request to finish
      Then I should see "DOMAIN NAME"
      And I should see "IMHUNGRY.COM"
      And I should see "REGISTRANT"
      And I should see "NAME SERVERS"
