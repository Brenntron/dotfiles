Feature: WebCat Bulk Resolution Tool
  Background:
    Given a user with role "webcat user" exists and is logged in
    And the following webcat resolution message templates exist:
      | name                | description                     | body                     | resolution_type |
      | Default Unchanged 1 | Default Unchanged 1 description | Default Unchanged 1 body | Unchanged       |
      | Default Unchanged 2 | Default Unchanged 2 description | Default Unchanged 2 body | Unchanged       |
      | Default Fixed 1     | Default Fixed 1 description     | Default Fixed 1 body     | Fixed           |
      | Default Fixed 2     | Default Fixed 2 description     | Default Fixed 2 body     | Fixed           |
      | Default Invalid 1   | Default Invalid 1 description   | Default Invalid 1 body   | Invalid         |
      | Default Invalid 2   | Default Invalid 2 description   | Default Invalid 2 body   | Invalid         |
    And the following complaint entries exist:
      | uri           | domain        | entry_type | status    | resolution |
      | url.com       | url.com       | URI/DOMAIN | COMPLETED |            |
      | url2.com      | url2.com      | URI/DOMAIN | PENDING   |            |
      | abc.com       | abc.com       | URI/DOMAIN | NEW       |            |
      | test.com      | test.com      | URI/DOMAIN | ASSIGNED  |            |
      | reopened.com  | reopened.com  | URI/DOMAIN | REOPENED  |            |
      | completed.com | completed.com | URI/DOMAIN | COMPLETED | FIXED      |
    And I go to "/escalations/webcat/complaints"
    And I wait for "2" seconds

  Rule: The Bulk Resolution Tool button only updates submittable rows
    @javascript
    Scenario: a webcat user selects one pending entry and one new entry
      When I click webcat row with id "2"
      And I shift click webcat row with id "3"
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I click "#webcat_resolution_unchanged_option"
      And I click "#apply_resolution_button"
      And I wait for "2" seconds
      Then I should see the radio with id "ignore2" checked
      And I should see the radio with id "unchanged3" checked
      And I should see content "Changes applied to submittable entries only." within ".bulk-warning"

  Rule: Submittable complaint entries should be updated by the bulk resolution tool
    @javascript
    Scenario: a webcat user updates a submittable tickets resolution
      When I click webcat row with id "3"
      And I shift click webcat row with id "4"
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I click "#webcat_resolution_unchanged_option"
      And I click "#apply_resolution_button"
      And I wait for "2" seconds
      Then I should see the radio with id "unchanged3" checked
      And I should see the radio with id "unchanged4" checked
      And I should see content "Applied bulk resolution changes to selected entries." within ".bulk-success"

    @javascript
    Scenario: a webcat user updates a submittable tickets customer comment with an email template
      When I click webcat row with id "3"
      And I shift click webcat row with id "4"
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I click "#webcat_resolution_unchanged_option"
      And I select "Default Unchanged 2" from "email-response-to-customers-select"
      And I click "#apply_resolution_button"
      And I wait for "2" seconds
      And I click "#resolution_comment_button3"
      Then I should see content "Default Unchanged 2 body" within "#entry-email-response-to-customers_3"
      And "Default Unchanged 2" should be selected in the "entry-email-response-to-customers-select_3" dropdown
      When I click "#resolution_comment_button4"
      Then I should see content "Default Unchanged 2 body" within "#entry-email-response-to-customers_4"
      And "Default Unchanged 2" should be selected in the "entry-email-response-to-customers-select_4" dropdown
      And I should see content "Applied bulk resolution changes to selected entries." within ".bulk-success"

    @javascript
    Scenario: a webcat user updates a submittable tickets customer comment with a modified template
      When I click webcat row with id "3"
      And I shift click webcat row with id "4"
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I click "#webcat_resolution_unchanged_option"
      And I select "Default Unchanged 2" from "email-response-to-customers-select"
      And I type content "modified" within input with id "customer_facing_comment"
      And I click "#apply_resolution_button"
      And I wait for "2" seconds
      And I click "#resolution_comment_button3"
      Then I should see content "Default Unchanged 2 body modified" within "#entry-email-response-to-customers_3"
      And "Default Unchanged 2" should be selected in the "entry-email-response-to-customers-select_3" dropdown
      When I click "#resolution_comment_button4"
      Then I should see content "Default Unchanged 2 body modified" within "#entry-email-response-to-customers_4"
      And "Default Unchanged 2" should be selected in the "entry-email-response-to-customers-select_4" dropdown
      And I should see content "Applied bulk resolution changes to selected entries." within ".bulk-success"

    @javascript
    Scenario: a webcat user updates a submittable tickets internal comment
      When I click webcat row with id "3"
      And I shift click webcat row with id "4"
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I fill in "internal_comment" with "This is an internal comment."
      And I click "#apply_resolution_button"
      And I wait for "2" seconds
      And I click "#internal_comment_button3"
      And I wait for "2" seconds
      Then I should see content "This is an internal comment." within "#internal_comment_3"
      When I click "#internal_comment_button3"
      And I click "#internal_comment_button4"
      And I wait for "2" seconds
      Then I should see content "This is an internal comment." within "#internal_comment_4"
      And I should see content "Applied bulk resolution changes to selected entries." within ".bulk-success"

  Rule: The apply button should be disabled until a submittable selected row is selected
    @javascript
    Scenario: a webcat user attempts to apply a customer facing comment before selecting a submittable ticket
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      Then button with id "apply_resolution_button" should be disabled
      When I click webcat row with id "3"
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      Then button with id "apply_resolution_button" should be enabled
      And I should see content "Applied bulk resolution changes to selected entries." within ".bulk-success"

  Rule: The Bulk Resolution Tool should apply updates to rows selected after a first round of updates.
    @javascript
    Scenario: a webcat user updates a submittable ticket's resolution and then updates a second selection
      When I click webcat row with id "3"
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I click "#webcat_resolution_unchanged_option"
      And I click "#apply_resolution_button"
      And I wait for "2" seconds
      Then I should see the radio with id "unchanged3" checked
      And I should see content "Applied bulk resolution changes to selected entries" within ".bulk-success"
      When I click webcat row with id "4"
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I click "#webcat_resolution_invalid_option"
      And I click "#apply_resolution_button"
      And I wait for "2" seconds
      Then I should see the radio with id "unchanged3" checked
      And I should see the radio with id "invalid4" checked
      And I should see content "Applied bulk resolution changes to selected entries." within ".bulk-success"

  Rule: The reset button should set the Bulk Resolution Tool fields to their default values but not affect the selected rows
    @javascript
    Scenario: a webcat user resets the Bulk Resolution Tool after adding changes to selected rows
      When I click webcat row with id "3"
      And I shift click webcat row with id "4"
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I click "#webcat_resolution_invalid_option"
      And I click "#apply_resolution_button"
      And I select "Default Invalid 2" from "email-response-to-customers-select"
      And I fill in "internal_comment" with "This is an internal comment."
      When I click ".resolution-clear-button"
      And I wait for "2" seconds
      Then I should see the radio with id "webcat_resolution_unchanged_option" checked
      And "Default Unchanged 1" should be selected in the "email-response-to-customers-select" dropdown
      And I should see content "Default Unchanged 1 body" within "#email-response-to-customers"
      And Input with id "internal_comment" should be empty

  Rule: Reopened tickets are also submittable
    @javascript
    Scenario: a webcat user updates resolution status, customer comment, and internal comments for reopened tickets
      When I click "#reopen_6"
      And I shift click webcat row with id "5"
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I click "#webcat_resolution_invalid_option"
      And I type content "test content" within input with id "customer_facing_comment"
      And I fill in "internal_comment" with "This is an internal comment."
      And I click "#apply_resolution_button"
      And I wait for "2" seconds
      Then I should see the radio with id "invalid5" checked
      And I should see the radio with id "invalid6" checked
      And I click "#resolution_comment_button5"
      And I should see content "test content" within "#entry-email-response-to-customers_5"
      When I click "#resolution_comment_button6"
      Then I should see content "test content" within "#entry-email-response-to-customers_6"
      When I click "#internal_comment_button5"
      And I wait for "2" seconds
      Then I should see content "This is an internal comment." within "#internal_comment_5"
      When I click "#internal_comment_button5"
      And I click "#internal_comment_button6"
      And I wait for "2" seconds
      Then I should see content "This is an internal comment." within "#internal_comment_6"
      And I should see content "Applied bulk resolution changes to selected entries." within ".bulk-success"
