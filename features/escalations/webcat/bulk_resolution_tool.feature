Feature: WebCat Bulk Resolution Tool
  Background:
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri      | domain   | entry_type | status    |
      | 1  | url.com  | url.com  | URI/DOMAIN | COMPLETED |
      | 2  | url2.com | url2.com | URI/DOMAIN | PENDING   |
      | 3  | abc.com  | abc.com  | URI/DOMAIN | NEW       |
      | 4  | test.com | test.com | URI/DOMAIN | ASSIGNED  |

  Rule: The Bulk Resolution Tool button only enables when a submittable row is selected
    @javascript
    Scenario: a webcat user selects one pending entry
      When I go to "/escalations/webcat/complaints"
      And I click row with id "2"
      Then button with id "index_update_resolution" should be disabled

    @javascript
    Scenario: a webcat user selects multiple non-pending entry
      When I go to "/escalations/webcat/complaints"
      And I click row with id "3"
      And I click row with id "4"
      And I wait for "2" seconds
      Then button with id "index_update_resolution" should be enabled
      When I click row with id "2"
      Then button with id "index_update_resolution" should be enabled
      When I click row with id "1"
      Then button with id "index_update_resolution" should be enabled

  Rule: Submittable complaint entries should be updated by the bulk resolution tool
    @javascript
    Scenario: a webcat user updates a submittable tickets resolution
      When I go to "/escalations/webcat/complaints"
      And I click row with id "3"
      And I click row with id "4"
      And I wait for "2" seconds
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I click "#webcat_resolution_unchanged_option"
      And I click "#resolution-apply-button"
      And I wait for "2" seconds
      Then I should see the radio with id "unchanged3" checked
      And I should see the radio with id "unchanged4" checked

    @javascript
    Scenario: a webcat user updates a submittable tickets customer comment
      When I go to "/escalations/webcat/complaints"
      And I click row with id "3"
      And I click row with id "4"
      And I wait for "2" seconds
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I type content "test content" within input with id "customer_facing_comment"
      And I click "#customer-facing-apply-button"
      And I wait for "2" seconds
      And I click "#resolution_comment_button3"
      Then I should see content "test content" within "#entry_email_response_to_customers_3"
      When I click "#resolution_comment_button4"
      Then I should see content "test content" within "#entry_email_response_to_customers_4"

    @javascript
    Scenario: a webcat user adds categories to submittable tickets
      When I go to "/escalations/webcat/complaints"
      And I fill in "input_cat_3-selectized" with "Arts"
      And I fill in "input_cat_4-selectized" with "Arts"
      And I click row with id "3"
      And I click row with id "4"
      And I wait for "2" seconds
      And I click "#index_update_resolution"
      When I fill in "webcat-bulk-categories-selectized" with "Auctions"
      And I click "#category-apply-button"
      And I wait for "2" seconds
      Then I should see selectized items "[Arts, Auctions]" within "#input_cat_3-selectized"
      And I should see selectized items "[Arts, Auctions]" within "#input_cat_4-selectized"

    @javascript
    Scenario: a webcat user replaces categories for submittable tickets
      When I go to "/escalations/webcat/complaints"
      And I fill in "input_cat_3-selectized" with "Arts"
      And I fill in "input_cat_4-selectized" with "Arts"
      And I click row with id "3"
      And I click row with id "4"
      And I wait for "2" seconds
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I fill in "webcat-bulk-categories-selectized" with "Arts"
      And I click "#category-apply-button"
      Then I should see content "Arts" within "#input_cat_3-selectized"
      And I should see content "Arts" within "#input_cat_4-selectized"
      When I fill in selectized of element "#webcat-bulk-categories" with "[88, 107, 110, 97, 82]"
      And I click "#webcat_resolution_replace_option"
      And I click "#category-apply-button"
      And I wait for "2" seconds
      Then I should not see content "Arts" within "#input_cat_3-selectized"
      And I wait for "2" seconds
      And I should not see content "Auctions" within "#input_cat_3"
      And I should see selectized items "['Animals and Pets', 'Conventions, Conferences and Trade Shows', 'DIY Projects', 'Digital Postcards']" within "#input_cat_3"
      And I should not see content "Arts" within "#input_cat_4-selectized"
      And I should see selectized items "['Animals and Pets', 'Conventions, Conferences and Trade Shows', 'DIY Projects', 'Digital Postcards']" within "#input_cat_4"

    @javascript
    Scenario: a webcat user drops categories for submittable tickets
      When I go to "/escalations/webcat/complaints"
      And I click row with id "3"
      And I click row with id "4"
      And I wait for "2" seconds
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
      When I go to "/escalations/webcat/complaints"
      And I click row with id "3"
      And I click row with id "4"
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
      When I go to "/escalations/webcat/complaints"
      And I click row with id "3"
      And I click row with id "4"
      And I wait for "2" seconds
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
      And I should see content "test content" within "#entry_email_response_to_customers_3"
      When I click "#resolution_comment_button4"
      Then I should see content "test content" within "#entry_email_response_to_customers_4"
      And I should see content "Arts" within "#input_cat_3-selectized"
      And I should see content "Arts" within "#input_cat_4-selectized"
      When I click "#internal_comment_button3"
      And I wait for "2" seconds
      Then I should see content "This is an internal comment." within "#internal_comment_3"
      When I click "#internal_comment_button3"
      And I click "#internal_comment_button4"
      And I wait for "2" seconds
      Then I should see content "This is an internal comment." within "#internal_comment_4"

  Rule: Staged changes from the bulk resolution tool should be removed when the apply button is toggled off or the clear button is clicked
    @javascript
    Scenario: a webcat user reverts updates to a submittable tickets resolution
      When I go to "/escalations/webcat/complaints"
      And I click row with id "3"
      And I click row with id "4"
      And I wait for "2" seconds
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I click "#webcat_resolution_unchanged_option"
      And I click "#resolution-apply-button"
      And I wait for "2" seconds
      Then I should see the radio with id "unchanged3" checked
      And I should see the radio with id "unchanged4" checked
      And I click "#resolution-apply-button"
      And I wait for "2" seconds
      Then I should see the radio with id "fixed3" checked
      And I should see the radio with id "fixed4" checked

    @javascript
    Scenario: a webcat user reverts updates to a submittable tickets customer comment
      When I go to "/escalations/webcat/complaints"
      And I click row with id "3"
      And I click row with id "4"
      And I wait for "2" seconds
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I type content "test content" within input with id "customer_facing_comment"
      And I click "#customer-facing-apply-button"
      And I wait for "2" seconds
      And I click "#resolution_comment_button3"
      Then I should see content "test content" within "#entry_email_response_to_customers_3"
      When I click "#resolution_comment_button4"
      Then I should see content "test content" within "#entry_email_response_to_customers_4"
      When I click "#index_update_resolution"
      And I click "#customer-facing-apply-button"
      And I wait for "2" seconds
      And I click "#resolution_comment_button3"
      Then I should not see content "test content" within "#entry_email_response_to_customers_3"
      When I click "#resolution_comment_button4"
      Then I should not see content "test content" within "#entry_email_response_to_customers_4"

    @javascript
    Scenario: a webcat user removes category updates to submittable tickets
      When I go to "/escalations/webcat/complaints"
      And I fill in "input_cat_3-selectized" with "Arts"
      And I fill in "input_cat_4-selectized" with "Arts"
      And I click row with id "3"
      And I click row with id "4"
      And I wait for "2" seconds
      And I click "#index_update_resolution"
      When I fill in "webcat-bulk-categories-selectized" with "Auctions"
      And I click "#category-apply-button"
      And I wait for "2" seconds
      Then I should see selectized items "[Arts, Auctions]" within "#input_cat_3-selectized"
      And I should see selectized items "[Arts, Auctions]" within "#input_cat_4-selectized"
      When I click "#category-apply-button"
      Then I should not see any selectized items within "#input_cat_3-selectized"
      And I should not see any selectized items within "#input_cat_4-selectized"

    @javascript
    Scenario: a webcat user reverts updates to a submittable tickets internal comment
      When I go to "/escalations/webcat/complaints"
      And I click row with id "3"
      And I click row with id "4"
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
      When I click "#internal-comment-button"
      And I click "#internal_comment_button3"
      Then I should not see content "This is an internal comment." within "#internal_comment_3"
      When I click "#internal_comment_button3"
      And I click "#internal_comment_button4"
      Then I should not see content "This is an internal comment." within "#internal_comment_4"

    @javascript
    Scenario: a webcat user enters changes to stage on submittble tickets and then resets the resolution tool
      When I go to "/escalations/webcat/complaints"
      And I click row with id "3"
      And I click row with id "4"
      And I wait for "2" seconds
      And I click "#index_update_resolution"
      And I wait for "2" seconds
      And I click "#webcat_resolution_invalid_option"
      And I type content "test content" within input with id "customer_facing_comment"
      And I fill in "webcat-bulk-categories-selectized" with "Arts"
      And I fill in "internal_comment" with "This is an internal comment."
      And I click ".apply-all-button"
      And I wait for "2" seconds
      Then I should see the radio with id "invalid3" checked
      And I should see the radio with id "invalid4" checked
      When I click "#resolution_comment_button3"
      Then I should see content "test content" within "#entry_email_response_to_customers_3"
      When I click "#resolution_comment_button4"
      Then I should see content "test content" within "#entry_email_response_to_customers_4"
      And I should see content "Arts" within "#input_cat_3-selectized"
      And I should see content "Arts" within "#input_cat_4-selectized"
      When I click "#internal_comment_button3"
      Then I should see content "This is an internal comment." within "#internal_comment_3"
      When I click "#internal_comment_button3"
      And I click "#internal_comment_button4"
      Then I should see content "This is an internal comment." within "#internal_comment_4"
      When I click ".resolution-clear-button"
      And I wait for "2" seconds
      Then I should see the radio with id "fixed3" checked
      And I should see the radio with id "fixed4" checked
      And I click "#resolution_comment_button3"
      Then I should not see content "test content" within "#entry_email_response_to_customers_3"
      When I click "#resolution_comment_button3"
      And I click "#resolution_comment_button4"
      Then I should not see content "test content" within "#entry_email_response_to_customers_4"
      And I should not see any selectized items within "#input_cat_3-selectized"
      And I should not see any selectized items within "#input_cat_4-selectized"
      When I click "#internal_comment_button3"
      Then I should not see content "This is an internal comment." within "#internal_comment_3"
      When I click "#internal_comment_button3"
      And I click "#internal_comment_button4"
      Then I should not see content "This is an internal comment." within "#internal_comment_4"
