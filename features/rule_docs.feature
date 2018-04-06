Feature: Rule Documents
  In order to view, create or edit rule documentation
  as a user
  I will provides ways to interact with rule documentation

  @javascript
  Scenario: A user can view a rule document
    Given a user with role "analyst" exists and is logged in
    And the following rule categories exist:
      | category  | id |
      | APP-DETECT |  1 |
    And the following "synched_rule" rules exist:
      | id | gid |  sid  | rev |     message       | rule_category_id |
      | 13 |  1  | 22212 |  3  | APP-DETECT message |        1         |
    And the following rule docs exist:
      |          summary              |     details      | rule_id |
      | Rule doc summary is here      | just a few deets |    13   |
    When I goto "/rule_docs"
    Then I should see "Rule doc summary is here"


  @javascript
  Scenario: A user can edit a rule document
    Given a user with role "analyst" exists and is logged in
    And the following rule categories exist:
      | category  | id |
      | APP-DETECT |  1 |
    And the following "synched_rule" rules exist:
      | id | gid |  sid  | rev |     message       | rule_category_id |
      | 13 |  1  | 22212 |  3  | APP-DETECT message |        1         |
    And the following rule docs exist:
      |          summary              |     details      | rule_id |
      | Rule doc summary is here      | just a few deets |    13   |
    When I goto "/rule_docs/1/edit"
    And I fill in "rule_doc[summary]" with "This is a new summary"
    And I fill in "rule_doc[details]" with "details details details"
    And I click "Save"
    And I wait for "2" seconds
    Then I should see "details details details"
    And I should see "This is a new summary"

  @javascript
  Scenario: A user can create a rule document
    Given a user with role "analyst" exists and is logged in
    And the following rule categories exist:
      | category  | id |
      | APP-DETECT |  1 |
    And the following "synched_rule" rules exist:
      | id | gid |  sid  | rev |     message       | rule_category_id |
      | 13 |  1  | 22212 |  3  | APP-DETECT message |        1        |
    When I goto "/rule_docs/new"
    And I fill in "rule_doc[gid]" with "1"
    And I fill in "rule_doc[sid]" with "22212"
    And I fill in "rule_doc[summary]" with "This is a new summary regarding sid 22212"
    And I fill in "rule_doc[details]" with "These are teh details"
    When I click "Save"
    And I wait for "2" seconds
    Then I should see "This is a new summary regarding sid 22212"

  @javascript
  Scenario: A user cannot create a rule document on a rule that already has a document
    Given a user with role "analyst" exists and is logged in
    And the following rule categories exist:
      | category  | id |
      | APP-DETECT |  1 |
    And the following "synched_rule" rules exist:
      | id | gid |  sid  | rev |     message       | rule_category_id |
      | 13 |  1  | 22212 |  3  | APP-DETECT message |        1        |
    And the following rule docs exist:
      |          summary              |     details      | rule_id |
      | Rule doc summary is here      | just a few deets |    13   |
    When I goto "/rule_docs/new"
    And I fill in "rule_doc[gid]" with "1"
    And I fill in "rule_doc[sid]" with "22212"
    And I fill in "rule_doc[summary]" with "This is a new summary regarding sid 22212"
    And I fill in "rule_doc[details]" with "These are teh details"
    When I click "Save"
    And I wait for "2" seconds
    Then I should see "Rule 1:22212 already has a document"


  @javascript
  Scenario: A user can delete a rule document
    Given a user with role "analyst" exists and is logged in
    And the following rule categories exist:
      | category  | id |
      | APP-DETECT |  1 |
    And the following "synched_rule" rules exist:
      | id | gid |  sid  | rev |     message       | rule_category_id |
      | 13 |  1  | 22212 |  3  | APP-DETECT message |        1        |
    And the following rule docs exist:
      |          summary              |     details      | rule_id |
      | Rule doc summary is here      | just a few deets |    13   |
    When I goto "/rule_docs"
    Then I should see "Rule doc summary is here"
    When I click ".delete-button"
    And I wait for "2" seconds
    Then I should not see "Rule doc summary is here"

  @javascript
  Scenario: A user can view bugs associated with the rule document
    Given a user with role "analyst" exists and is logged in
    Given the following bugs exist:
      |  id  | bugzilla_id | state  | user_id |
      | 2222 |   222222    | OPEN   |    1    |
    And the following rule categories exist:
      | category  | id |
      | APP-DETECT |  1 |
    And the following "synched_rule" rules exist:
      | id | gid |  sid  | rev |     message       | rule_category_id |
      | 13 |  1  | 22212 |  3  | APP-DETECT message |        1        |
    And the following rule docs exist:
      |          summary              |     details      | rule_id |
      | Rule doc summary is here      | just a few deets |    13   |
    And bug with id "2222" has rule with id "13"
    When I goto "/rule_docs/1/edit"
    Then I should see "222222"

  @javascript
  Scenario: A user can not view rules associated with the rule document
    Given a user with role "analyst" exists and is logged in
    And the following rule categories exist:
      | category  | id |
      | APP-DETECT |  1 |
    And the following "synched_rule" rules exist:
      | id | gid |  sid  | rev |     message       | rule_category_id |
      | 13 |  1  | 22212 |  3  | APP-DETECT message |        1        |
    And the following rule docs exist:
      |          summary              |     details      | rule_id |
      | Rule doc summary is here      | just a few deets |    13   |
    When I goto "/rule_docs/1/edit"
    Then I should not see "Rules referencing this doc"

  @javascript
  Scenario: An admin user can view rules associated with the rule document
    Given an admin user with role "analyst" exists and is logged in
    And the following rule categories exist:
      | category  | id |
      | APP-DETECT |  1 |
    And the following "synched_rule" rules exist:
      | id | gid |  sid  | rev |     message       | rule_category_id |
      | 13 |  1  | 22212 |  3  | APP-DETECT message |        1        |
    And the following rule docs exist:
      |          summary              |     details      | rule_id |
      | Rule doc summary is here      | just a few deets |    13   |
    When I goto "/rule_docs/1/edit"
    Then I should see "Rules referencing this doc"

  @javascript
  Scenario: A document must contain a sid and gid
    Given a user with role "analyst" exists and is logged in
    And the following rule categories exist:
      | category  | id |
      | APP-DETECT |  1 |
    And the following "synched_rule" rules exist:
      | id | gid |  sid  | rev |     message       | rule_category_id |
      | 13 |  1  | 22212 |  3  | APP-DETECT message |        1        |
    When I goto "/rule_docs/new"
    And I fill in "rule_doc[summary]" with "a summary"
    And I fill in "rule_doc[details]" with "some details"
    When I click "Save"
    And I wait for "2" seconds
    Then I should see "Creating New Rule Document"

  @javascript
  Scenario: A document must contain a summary and detailed info
    Given a user with role "analyst" exists and is logged in
    And the following rule categories exist:
      | category  | id |
      | APP-DETECT |  1 |
    And the following "synched_rule" rules exist:
      | id | gid |  sid  | rev |     message       | rule_category_id |
      | 13 |  1  | 22212 |  3  | APP-DETECT message |        1        |
    When I goto "/rule_docs/new"
    And I fill in "rule_doc[gid]" with "1"
    And I fill in "rule_doc[sid]" with "22212"
    When I click "Save"
    And I wait for "2" seconds
    Then I should see "Creating New Rule Document"

  @javascript
  Scenario: A document alerts if a document is a duplicate
    Given a user with role "analyst" exists and is logged in
    And the following rule categories exist:
      | category  | id |
      | APP-DETECT |  1 |
    And the following "synched_rule" rules exist:
      | id | gid |  sid  | rev |     message       | rule_category_id |
      | 13 |  1  | 22212 |  3  | APP-DETECT message |        1        |
      | 12 |  1  | 22213 |  1  | APP-DETECT message |        1        |
    And the following rule docs exist:
      |          summary              |     details                    | rule_id |
      | Rule doc summary is here      | just a few deets               |    13   |
      | The second summary is this    | woah now lets not get detailed |    12   |
    Then I cannot programatically assign doc "2" with rule "13"
