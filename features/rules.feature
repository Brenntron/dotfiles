Feature: Rules
  In order to import, create or edit rules
  as a user
  I will provides ways to interact with rules

 # ==== Appending the rule category to the Rule message ===
  @javascript
  Scenario: A new rule can be created with a rule category
    Given a user exists and is logged in
    And the following bugs exist:
      | id      | bugzilla_id | state  | user_id | summary             | product | component   | version | description       |
      |222222   | 222222      | OPEN   | 1       | [BP][NSS] fixed bug | Research| Snort Rules | 2.6.0   | test description3 |
    And the following rule categories exist:
      |category       |
      |BLACKLIST      |
      |FILE-EXECUTABLE|
      |OS-LINUX       |
    Then I wait for "3" seconds
    And  I goto "/bugs/222222"
    And  I should see "222222"
    Then I click the "Rules" tab
    Then I click button "create"
    Then I click "use standard form"
    And  I should see "New Rule"
    And  I select "FILE-EXECUTABLE" from "rule_category_id"
    And  I fill in "rule[message]" with "Test Message"
    Then I click "Create Rule"
    And  I wait for "3" seconds
    Then I click the "Rules" tab
    Then I click button "list all"
    And  I should see "FILE-EXECUTABLE Test Message"

  @javascript
  Scenario: Rule category drop down should sort by frequency of use
  Given a user exists and is logged in
    And the following bugs exist:
      | id      | bugzilla_id | state  | user_id | summary             | product | component   | version | description       |
      |222222   | 222222      | OPEN   | 1       | [BP][NSS] fixed bug | Research| Snort Rules | 2.6.0   | test description3 |
    And the following rule categories exist:
      |category       | id |
      |BLACKLIST      |  1 |
      |FILE-EXECUTABLE|  2 |
      |OS-LINUX       |  3 |
    And the following rules exist:
      | message                 | rule_category_id |
      | BLACKLIST message       | 1                |
      | OS-LINUX message        | 3                |
      | OS-LINUX second message | 3                |
    Then I wait for "3" seconds
    And  I goto "/bugs/222222"
    Then I click the "Rules" tab
    Then I click button "create"
    Then I click "use standard form"
    Then "OS-LINUX" should be listed first
    And  I select "BLACKLIST" from "rule_category_id"
    And  I fill in "rule[message]" with "Test Message"
    Then I click "Create Rule"
    And  I wait for "3" seconds
    Then I click the "Rules" tab
    Then I click button "create"
    Then I click "use standard form"
    Then "BLACKLIST" should be listed first




  # ==== Importing a rule ===