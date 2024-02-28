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

  Rule: The Bulk Resolution Tool button only updates submitable rows
    @javascript
    Scenario: a webcat user selects one pending entry
      When I click webcat row with id "2"
      And I shift click webcat row with id "3"
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I click "#webcat_resolution_unchanged_option"
      And I click "#resolution-apply-button"
      And I wait for "2" seconds
      Then I should see the radio with id "ignore2" checked
      And I should see the radio with id "unchanged3" checked

  Rule: Submittable complaint entries should be updated by the bulk resolution tool
    @javascript
    Scenario: a webcat user updates a submittable tickets resolution
      When I click webcat row with id "3"
      And I shift click webcat row with id "4"
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I click "#webcat_resolution_unchanged_option"
      And I click "#resolution-apply-button"
      And I wait for "2" seconds
      Then I should see the radio with id "unchanged3" checked
      And I should see the radio with id "unchanged4" checked

    @javascript
    Scenario: a webcat user updates a submittable tickets customer comment with an email template
      When I click webcat row with id "3"
      And I shift click webcat row with id "4"
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I click "#webcat_resolution_unchanged_option"
      And I click "#resolution-apply-button"
      And I select "Default Unchanged 2" from "email-response-to-customers-select"
      And I click "#customer-facing-apply-button"
      And I wait for "2" seconds
      And I click "#resolution_comment_button3"
      Then I should see content "Default Unchanged 2 body" within "#entry-email-response-to-customers_3"
      And "Default Unchanged 2" should be selected in the "entry-email-response-to-customers-select_3" dropdown
      When I click "#resolution_comment_button4"
      Then I should see content "Default Unchanged 2 body" within "#entry-email-response-to-customers_4"
      And "Default Unchanged 2" should be selected in the "entry-email-response-to-customers-select_4" dropdown

    @javascript
    Scenario: a webcat user updates a submittable tickets customer comment with a modified template
      When I click webcat row with id "3"
      And I shift click webcat row with id "4"
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I click "#index_update_resolution"
      And I click "#webcat_resolution_unchanged_option"
      And I click "#resolution-apply-button"
      And I select "Default Unchanged 2" from "email-response-to-customers-select"
      And I type content "modified" within input with id "customer_facing_comment"
      And I click "#customer-facing-apply-button"
      And I wait for "2" seconds
      And I click "#resolution_comment_button3"
      Then I should see content "Default Unchanged 2 body modified" within "#entry-email-response-to-customers_3"
      And "Default Unchanged 2" should be selected in the "entry-email-response-to-customers-select_3" dropdown
      When I click "#resolution_comment_button4"
      Then I should see content "Default Unchanged 2 body modified" within "#entry-email-response-to-customers_4"
      And "Default Unchanged 2" should be selected in the "entry-email-response-to-customers-select_4" dropdown

    @javascript
    Scenario: a webcat user adds categories to submittable tickets
      When I fill in "input_cat_3-selectized" with "Arts"
      And I fill in "input_cat_4-selectized" with "Arts"
      And I click webcat row with id "3"
      And I click webcat row with id "4"
      And I click "#index_update_resolution"
      When I fill in "webcat-bulk-categories-selectized" with "Auctions"
      And I click "#category-apply-button"
      And I wait for "2" seconds
      Then I should see selectized items "[Arts, Auctions]" within "#input_cat_3-selectized"
      And I should see selectized items "[Arts, Auctions]" within "#input_cat_4-selectized"

    @javascript
    Scenario: a webcat user replaces categories for submittable tickets
      When I fill in "input_cat_3-selectized" with "Auctions"
      And I fill in "input_cat_4-selectized" with "Arts"
      And I click webcat row with id "3"
      And I shift click webcat row with id "4"
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      When I fill in selectized of element "#webcat-bulk-categories" with "[88, 107, 110, 97, 82]"
      And I click "#webcat_resolution_replace_option"
      And I click "#category-apply-button"
      And I click ".ui-dialog-titlebar-close"
      And I wait for "2" seconds
      And I should not see content "Auctions" within "#input_cat_3-selectized"
      And I should see selectized items "['Animals and Pets', 'Conventions, Conferences and Trade Shows', 'DIY Projects', 'Digital Postcards']" within "#input_cat_3"
      And I should not see content "Arts" within "#input_cat_4-selectized"
      And I should see selectized items "['Animals and Pets', 'Conventions, Conferences and Trade Shows', 'DIY Projects', 'Digital Postcards']" within "#input_cat_4"

    @javascript
    Scenario: a webcat user drops categories for submittable tickets
      When I click webcat row with id "3"
      And I click webcat row with id "4"
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I fill in "webcat-bulk-categories-selectized" with "Arts"
      And I click "#category-apply-button"
      Then I should see content "Arts" within "#input_cat_3-selectized"
      And I should see content "Arts" within "#input_cat_4-selectized"
      When I click "#webcat_resolution_drop_option"
      And I click "#category-apply-button"
      Then I should not see content "Arts" within "#input_cat_3-selectized"
      And I should not see content "Arts" within "#input_cat_4-selectized"

    @javascript
    Scenario: a webcat user updates a submittable tickets internal comment
      When I click webcat row with id "3"
      And I click webcat row with id "4"
      And I wait for "2" seconds
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I fill in "internal_comment" with "This is an internal comment."
      And I click "#internal-comment-button"
      And I click "#internal_comment_button3"
      And I wait for "2" seconds
      Then I should see content "This is an internal comment." within "#internal_comment_3"
      When I click "#internal_comment_button3"
      And I click "#internal_comment_button4"
      And I wait for "2" seconds
      Then I should see content "This is an internal comment." within "#internal_comment_4"

    @javascript
    Scenario: a webcat user updates resolution status, customer comment, categories and internal comments with the APPLY ALL button
      When I click webcat row with id "3"
      And I shift click webcat row with id "4"
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I click "#webcat_resolution_invalid_option"
      And I type content "test content" within input with id "customer_facing_comment"
      And I fill in "webcat-bulk-categories-selectized" with "Arts"
      And I fill in "internal_comment" with "This is an internal comment."
      And I click "#internal-comment-button"
      And I click ".apply-all-button"
      And I wait for "2" seconds
      Then I should see the radio with id "invalid3" checked
      And I should see the radio with id "invalid4" checked
      And I click "#resolution_comment_button3"
      And I should see content "test content" within "#entry-email-response-to-customers_3"
      When I click "#resolution_comment_button4"
      Then I should see content "test content" within "#entry-email-response-to-customers_4"
      And I should see content "Arts" within "#input_cat_3-selectized"
      And I should see content "Arts" within "#input_cat_4-selectized"
      When I click "#internal_comment_button3"
      And I wait for "2" seconds
      Then I should see content "This is an internal comment." within "#internal_comment_3"
      When I click "#internal_comment_button3"
      And I click "#internal_comment_button4"
      And I wait for "2" seconds
      Then I should see content "This is an internal comment." within "#internal_comment_4"

  Rule: The customer facing comments button should be disabled until a submittable selected row is changed
    @javascript
    Scenario: a webcat user attempts to apply a customer facing comment before selecting a submittable ticket
      When I click webcat row with id "2"
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I select "Default Unchanged 1" from "email-response-to-customers-select"
      Then button with id "customer-facing-apply-button" should be disabled
      When I click webcat row with id "3"
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I click "#webcat_resolution_unchanged_option"
      And I click "#resolution-apply-button"
      And I select "Default Unchanged 1" from "email-response-to-customers-select"
      Then button with id "customer-facing-apply-button" should be enabled

  Rule: the Internal Comment and Category buttons should be disabled until a row is selected
    @javascript
    Scenario: a webcat user attempts to apply an internal comment and category without selecting a row
      When I click "#index_update_resolution"
      And I wait for "2" seconds
      Then button with id "category-apply-button" should be disabled
      And button with id "internal-comment-button" should be disabled

    @javascript
    Scenario: a webcat user attempts to apply an internal comment and category after selecting a row
      When I click webcat row with id "3"
      And I click "#index_update_resolution"
      And I click "#webcat_resolution_replace_option"
      And I fill in "internal_comment" with "This is an internal comment."
      Then button with id "category-apply-button" should be enabled
      And button with id "internal-comment-button" should be enabled

  Rule: The Bulk Resolution Tool should apply updates to rows selected after a first round of updates.
    @javascript
    Scenario: a webcat user updates a submittable ticket's resolution and then updates a second selection
      When I click webcat row with id "3"
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I click "#webcat_resolution_unchanged_option"
      And I click "#resolution-apply-button"
      And I wait for "2" seconds
      Then I should see the radio with id "unchanged3" checked
      And I click webcat row with id "4"
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I click "#webcat_resolution_invalid_option"
      And I click "#resolution-apply-button"
      And I wait for "2" seconds
      Then I should see the radio with id "unchanged3" checked
      And I should see the radio with id "invalid4" checked

  Rule: The reset button should set the Bulk Resolution Tool fields to their default values but not affect the selected rows
    @javascript
    Scenario: a webcat user resets the Bulk Resolution Tool after adding changes to selected rows
      When I click webcat row with id "3"
      And I shift click webcat row with id "4"
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I click "#webcat_resolution_invalid_option"
      And I click "#resolution-apply-button"
      And I select "Default Invalid 2" from "email-response-to-customers-select"
      And I click "#webcat_resolution_replace_option"
      And I fill in "webcat-bulk-categories-selectized" with "Auctions"
      And I fill in "internal_comment" with "This is an internal comment."
      When I click ".resolution-clear-button"
      And I wait for "2" seconds
      Then I should see the radio with id "webcat_resolution_unchanged_option" checked
      And "Default Unchanged 1" should be selected in the "email-response-to-customers-select" dropdown
      And I should see content "Default Unchanged 1 body" within "#email-response-to-customers"
      And I should see the radio with id "webcat_resolution_add_option" checked
      And Input with id "internal_comment" should be empty

  Rule: Reopened tickets are also submitable
    @javascript
    Scenario: a webcat user updates resolution status, customer comment, categories and internal comments for reopened tickets
      When I click "#reopen_6"
      And I shift click webcat row with id "5"
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I click "#webcat_resolution_invalid_option"
      And I type content "test content" within input with id "customer_facing_comment"
      And I fill in "webcat-bulk-categories-selectized" with "Arts"
      And I fill in "internal_comment" with "This is an internal comment."
      And I click "#internal-comment-button"
      And I click ".apply-all-button"
      And I wait for "2" seconds
      Then I should see the radio with id "invalid5" checked
      And I should see the radio with id "invalid6" checked
      And I click "#resolution_comment_button5"
      And I should see content "test content" within "#entry-email-response-to-customers_5"
      When I click "#resolution_comment_button6"
      Then I should see content "test content" within "#entry-email-response-to-customers_6"
      And I should see content "Arts" within "#input_cat_5-selectized"
      And I should see content "Arts" within "#input_cat_6-selectized"
      When I click "#internal_comment_button5"
      And I wait for "2" seconds
      Then I should see content "This is an internal comment." within "#internal_comment_5"
      When I click "#internal_comment_button5"
      And I click "#internal_comment_button6"
      And I wait for "2" seconds
      Then I should see content "This is an internal comment." within "#internal_comment_6"
