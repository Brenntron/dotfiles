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

  @javascript
  Scenario: user should see important label if there is important clusters
    Given a user with id "1" has a role "webcat user" and is logged in
    And WBRS TopUrl API call is stubbed with:
      |   url   | is_important |
      | food.com|     true     |
      | blah.com|     false    |
    And WBRS Cluster returns the following stubbed clusters:
      |id|  domain      |
      |1 | food.com     |
      |2 | blah.com     |
    And the following cluster assignments exists:
      |id| user_id | cluster_id |
      |1 |    1    |     1      |
      |2 |    1    |     2      |
    When I goto "/escalations/webcat/clusters"
    And I wait for "3" seconds
    And I should see element ".is-important"


  @javascript
  Scenario: user should not see important label if there are no important clusters
    Given a user with id "1" has a role "webcat user" and is logged in
    And WBRS TopUrl API call is stubbed with:
      |   url   | is_important |
      | food.com|     false    |
      | blah.com|     false    |
    And WBRS Cluster returns the following stubbed clusters:
      |id|  domain      |
      |1 | food.com     |
      |2 | blah.com     |
    And the following cluster assignments exists:
      |id| user_id | cluster_id |
      |1 |    1    |     1      |
      |2 |    1    |     2      |
    When I goto "/escalations/webcat/clusters"
    And I wait for "3" seconds
    And I should not see element ".is-important"

  @javascript
  Scenario: an important cluster should go to 2nd person review after categorization
    Given a user with id "1" has a role "webcat user" and is logged in
    And WBRS TopUrl API call is stubbed with:
      |   url   | is_important |
      | food.com|     true     |
      | blah.com|     false    |
    And WBRS Cluster returns the following stubbed clusters:
      |id|  domain      |
      |1 | food.com     |
      |2 | blah.com     |
    And the following cluster assignments exists:
      |id| user_id | cluster_id |
      |1 |    1    |     1      |
      |2 |    1    |     2      |
    When I goto "/escalations/webcat/clusters"
    And I wait for "3" seconds
    Then I check "cluster_id_1"
    And I fill in selectized of element "#1_categories" with "[6]"
    Then I click "Submit Changes"
    And I wait for "5" seconds
    Then I should see button with class "cluster-submit-button"
    And I should see button with class "cluster-cancel-button"

  @javascript
  Scenario: a user should be able to see "waiting for review" clusters
    Given a user with id "1" has a role "webcat user" and is logged in
    And WBRS TopUrl API call is stubbed with:
      |   url   | is_important |
      | food.com|     true     |
      | blah.com|     false    |
    And WBRS Cluster returns the following stubbed clusters:
      |id|  domain      |
      |1 | food.com     |
      |2 | blah.com     |
    And the following cluster assignments exists:
      |id| user_id | cluster_id |
      |1 |    1    |     1      |
      |2 |    1    |     2      |
    When I goto "/escalations/webcat/clusters"
    And I wait for "3" seconds
    Then I check "cluster_id_1"
    And I fill in selectized of element "#1_categories" with "[6]"
    Then I click "Submit Changes"
    And I wait for "5" seconds
    Then I click "#filter-clusters"
    And I click link "Waiting For Review"
    Then I wait for "3" seconds
    Then I should see "food.com"
    And I should not see "blah.com"

  @javascript
  Scenario: user can submit cluster on 2nd person review
    Given a user with id "1" has a role "webcat user" and is logged in
    And WBRS TopUrl API call is stubbed with:
      |   url   | is_important |
      | food.com|     true     |
      | blah.com|     false    |
    And WBRS Cluster returns the following stubbed clusters:
      |id|  domain      |
      |1 | food.com     |
      |2 | blah.com     |
    And the following cluster assignments exists:
      |id| user_id | cluster_id |
      |1 |    1    |     1      |
      |2 |    1    |     2      |
    When I goto "/escalations/webcat/clusters"
    And I wait for "3" seconds
    Then I check "cluster_id_1"
    And I fill in selectized of element "#1_categories" with "[6]"
    Then I click "Submit Changes"
    And I wait for "5" seconds
    Then I click button with class "cluster-submit-button"
    And I wait for "5" seconds
    Then I should see "CLUSTER WAS SUBMITTED."
    And I click "#msg-modal"
    And I wait for "5" seconds
    Then I should not see button with class "cluster-submit-button"
    And I should not see button with class "cluster-cancel-button"

  @javascript
  Scenario: user can decline cluster categorization on 2nd person review
    Given a user with id "1" has a role "webcat user" and is logged in
    And WBRS TopUrl API call is stubbed with:
      |   url   | is_important |
      | food.com|     true     |
      | blah.com|     false    |
    And WBRS Cluster returns the following stubbed clusters:
      |id|  domain      |
      |1 | food.com     |
      |2 | blah.com     |
    And the following cluster assignments exists:
      |id| user_id | cluster_id |
      |1 |    1    |     1      |
      |2 |    1    |     2      |
    When I goto "/escalations/webcat/clusters"
    And I wait for "3" seconds
    Then I check "cluster_id_1"
    And I fill in selectized of element "#1_categories" with "[6]"
    Then I click "Submit Changes"
    And I wait for "5" seconds
    Then I click button with class "cluster-cancel-button"
    And I wait for "5" seconds
    Then I should see "CLUSTER CATEGORIES WERE DECLINED."
    And I click "#msg-modal"
    And I wait for "5" seconds
    Then I should not see button with class "cluster-submit-button"
    And I should not see button with class "cluster-cancel-button"

  @javascript
  Scenario: cluster should be assigned to the user who declined categorization
    Given a user with id "1" has a role "webcat user" and is logged in
    And WBRS TopUrl API call is stubbed with:
      |   url   | is_important |
      | food.com|     true     |
      | blah.com|     false    |
    And WBRS Cluster returns the following stubbed clusters:
      |id|  domain      |
      |1 | food.com     |
      |2 | blah.com     |
    And the following cluster assignments exists:
      |id| user_id | cluster_id |
      |1 |    1    |     1      |
      |2 |    1    |     2      |
    When I goto "/escalations/webcat/clusters"
    And I wait for "3" seconds
    Then I check "cluster_id_1"
    And I fill in selectized of element "#1_categories" with "[6]"
    Then I click "Submit Changes"
    And I wait for "5" seconds
    Then I click button with class "cluster-cancel-button"
    And I wait for "5" seconds
    Then I should see "CLUSTER CATEGORIES WERE DECLINED."
    And I click "#msg-modal"
    And I wait for "5" seconds
    Then I should see my username in element "#owner_1"

  @javascript
  Scenario: non important complaints should be submitted without 2nd person review
    Given a user with id "1" has a role "webcat user" and is logged in
    And WBRS TopUrl API call is stubbed with:
      |   url   | is_important |
      | food.com|     true     |
      | blah.com|     false    |
    And WBRS Cluster returns the following stubbed clusters:
      |id|  domain      |
      |1 | food.com     |
      |2 | blah.com     |
    And the following cluster assignments exists:
      |id| user_id | cluster_id |
      |1 |    1    |     1      |
      |2 |    1    |     2      |
    When I goto "/escalations/webcat/clusters"
    And I wait for "3" seconds
    Then I check "cluster_id_2"
    And I fill in selectized of element "#2_categories" with "[6]"
    Then I click "Submit Changes"
    And I wait for "5" seconds
    Then I should not see button with class "cluster-submit-button"
    And I should not see button with class "cluster-cancel-button"
