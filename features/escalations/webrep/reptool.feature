Feature: Reptool Dropdown
  Verify that all Adjust Reptool functionality is working
  Comments need to be appearing and submitting properly

  @javascript
  Scenario: a user submits a change to an entry's reptool classification using the bulk reptool dropdown
    Given a user with role "webrep user" exists and is logged in
    Given the following disputes exist:
      | id | submission_type |
      | 1  | w               |
    Given the following dispute_entries exist:
      | id | uri             |
      | 1  | thisisatest.com |
    And I resize the browser to "1600" X "1000"
    When I goto "escalations/webrep/disputes?f=open"
    And I wait for "2" seconds
    And I click ".expand-row-button-inline"
    And I click ".dispute-entry-checkbox"
    And I click "#reptool_index_entries_button"
    And I wait for "2" seconds
    Then I should see "Adjust Reptool Classification"
    And I should see "AC Bulk Submission:"
    And I should see "TE.ACE-00001"
    And I check checkbox with class "reptool-cb-attackers"
    And I fill in "typed-in-comment-bulk" with "Test comment for bulk."
    And I click ".dropdown-submit-button"
    And I wait for "2" seconds
    Then I goto "escalations/webrep/disputes/1"
    And I wait for "3" seconds
    And I click "research-tab-link"
    And I should see "Research Data"
    And I should see "Test comment for bulk."

  @javascript
  Scenario: a user submits a change to an entry's reptool classification using the inline reptool dropdown
    Given a user with role "webrep user" exists and is logged in
    Given the following disputes exist:
      | id | submission_type |
      | 1  | w               |
    Given the following dispute_entries exist:
      | id | uri                  |
      | 1  | amazingteststuff.com |
    And I resize the browser to "1600" X "1000"
    When I goto "escalations/webrep/disputes/1"
    And I wait for "2" seconds
    And I click "research-tab-link"
    And I should see "Research Data"
    And I should see "amazingteststuff.com"
    And I click "reptool_button_1"
    And I should see "Adjust RepTool Classification"
    And I check checkbox with class "reptool-cb-bots"
    And I fill in "typed-in-comment-inline" with "Test comment for inline."
    And I click ".dropdown-submit-button"
    And I wait for "2" seconds
    And I click ".close"
    And I click ".sync-button"
    And I wait for "5" seconds
    And I should see "Test comment for inline."

  @javascript
  Scenario: a user submits an autogenerated comment using the bulk reptool dropdown
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
      | id | submission_type |
      | 1  | w               |
      | 2  | w               |
    And the following dispute_entries exist:
      | id | uri             | dispute_id |
      | 1  | thisisatest.com |  1         |
      | 2  | example.com     |  2         |
    When I goto "escalations/webrep/disputes?f=open"
    And I wait for "2" seconds
    And I click "#expand-all-index-rows"
    And I check checkbox with class "dispute-entry-checkbox_1"
    And I check checkbox with class "dispute-entry-checkbox_2"
    And I click "#reptool_index_entries_button"
    Then I should see "Adjust Reptool Classification"
    And I should see content "AC Bulk Submission:" within ".reptool-generated-comment"
    And I should see content "TE.ACE-00001" within ".reptool-generated-comment"
    And I should see content "TE.ACE-00002" within ".reptool-generated-comment"
    Then I check checkbox with class "reptool-cb-attackers"
    And I click ".dropdown-submit-button"
    And I wait for "2" seconds
    Then I goto "escalations/webrep/disputes?f=open"
    And I click "#expand-all-index-rows"
    And I check checkbox with class "dispute-entry-checkbox_1"
    And I check checkbox with class "dispute-entry-checkbox_2"
    And I click "#reptool_index_entries_button"
    Then I should see content "AC Bulk Submission:" within ".reptool-entry-comment" at least once
    And I should see content "TE.ACE-00001" within ".reptool-entry-comment" at least once
    And I should see content "TE.ACE-00002" within ".reptool-entry-comment" at least once

  @javascript
  Scenario: a user submits an autogenerated comment using the reptool dropdown on top navbar
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
      | id |
      | 1  |
    And the following dispute_entries exist:
      | id | uri             | dispute_id |
      | 1  | thisisatest.com |  1         |
      | 2  | example.com     |  1         |
    When I goto "escalations/webrep/disputes/1"
    And I wait for "2" seconds
    And I click "research-tab-link"
    And I check checkbox with class "dispute-entry-cb-1"
    And I check checkbox with class "dispute-entry-cb-2"
    And I click "#reptool_entries_button"
    Then I should see "Current Reptool Classification"
    And I should see content "AC INDIVIDUAL SUBMISSION:" I should see content "AC INDIVIDUAL SUBMISSION:" within ".reptool-generated-comment"
    And I should see content "TE.ACE-00001" within ".reptool-generated-comment"
    Then I check checkbox with class "reptool-cb-attackers"
    And I click ".dropdown-submit-button"
    And I wait for "2" seconds
    When I goto "escalations/webrep/disputes/1"
    And I wait for "2" seconds
    And I click "research-tab-link"
    And I check checkbox with class "dispute-entry-cb-1"
    And I check checkbox with class "dispute-entry-cb-2"
    And I click "#reptool_entries_button"
    And I wait for "3" seconds
    Then I should see content "AC INDIVIDUAL SUBMISSION:" within ".reptool-entry-comment" at least once
    And I should see content "TE.ACE-00001" within ".reptool-entry-comment" at least once

  @javascript
  Scenario: a user submits an autogenerated comment using the reptool dropdown for specific entry
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
      | id |
      | 1  |
    And the following dispute_entries exist:
      | id | uri             | dispute_id |
      | 1  | thisisatest.com |  1         |
    When I goto "escalations/webrep/disputes/1"
    And I wait for "2" seconds
    And I click "research-tab-link"
    And I click "#reptool_button_1"
    Then I should see "Adjust RepTool Classification"
    And I should see content "AC INDIVIDUAL SUBMISSION:" within ".reptool-generated-comment"
    And I should see content "TE.ACE-00001" within ".reptool-generated-comment"
    Then I check checkbox with class "reptool-cb-attackers"
    And I click ".dropdown-submit-button"
    And I wait for "2" seconds
    When I goto "escalations/webrep/disputes/1"
    And I wait for "2" seconds
    And I click "research-tab-link"
    And I click "#reptool_button_1"
    And I wait for "3" seconds
    Then I should see content "AC INDIVIDUAL SUBMISSION:" within ".reptool-entry-comment" at least once
    And I should see content "TE.ACE-00001" within ".reptool-entry-comment" at least once