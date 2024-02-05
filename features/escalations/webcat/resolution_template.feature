Feature: Webcat resolution template manager

  Background:
    Given a guest company exists

  @javascript
  Scenario: A manager can create a new webcat resolution message template
    Given a user with role "webcat manager" exists and is logged in
    And the following complaint entries exist:
      | id  | uri            | domain          | entry_type | status |
      | 111 | abc.com        | abc.com         | URI/DOMAIN | NEW    |
      | 222 | google.com     | google.com      | URI/DOMAIN | NEW    |
    And the following resolution message templates exist:
      |body                                   |resolution_type      |ticket_type                |name           |description        |
      |This is the first unchanged comment    |Unchanged            |WebCategoryDispute         |Unchanged - 01 |First Unchanged    |
      |This is the second unchanged comment   |Unchanged            |WebCategoryDispute         |Unchanged - 02 |Second Unchanged   |
      |This is the first invalid comment      |Invalid              |WebCategoryDispute         |Invalid - 01   |First Invalid      |
      |This is the second invalid comment     |Invalid              |WebCategoryDispute         |Invalid - 02   |Second Invalid     |
      |This is the first fixed comment        |Fixed                |WebCategoryDispute         |Fixed - 01     |First Fixed        |
      |This is the second fixed comment       |Fixed                |WebCategoryDispute         |Fixed - 02     |Second Fixed       |
    Then I go to "/escalations/webcat/resolution_message_templates"
    And I should see "Manage Resolution Templates"
    And the table "resolution-message-templates-table" should have "6" number of rows
    Then I click button with class "add-message-template"
    And I should see "Create Resolution Template"
    Then I click "#create-form_resolution_type"
    Then I click element with tag "option" and text "Fixed"
    And button "create-resolution-template-submit" should be disabled
    Then I fill in element, "#create-resolution-template-name" with "Fixed 03 Name"
    Then I fill in element, "#create-resolution-template-description" with "Fixed 03 Description"
    Then I fill in element, "#create-resolution-template-message" with "Fixed 03 Message"
    Then I click button "create-resolution-template-submit"
    And I wait for "2" seconds
    And I should see "RESOLUTION MESSAGE TEMPLATE CREATED"

#  @javascript
#  Scenario: A user can load the resolution templates using the actions in the bulk resolution tool
#    Given a user with role "webcat user" exists and is logged in
#
#  @javascript
#  Scenario: A user can view the current resolutions in the resolution management table
#    Given a user with role "webcat user" exists and is logged in

  @javascript
  Scenario: A user can load the resolution templates using the actions in the resolution column
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri            | domain          | entry_type | status |
      | 111 | abc.com        | abc.com         | URI/DOMAIN | NEW    |
      | 222 | google.com     | google.com      | URI/DOMAIN | NEW    |
    And the following resolution message templates exist:
      |body                                   |resolution_type      |ticket_type                |name           |description        |
      |This is the first unchanged comment    |Unchanged            |WebCategoryDispute         |Unchanged - 01 |First Unchanged    |
      |This is the second unchanged comment   |Unchanged            |WebCategoryDispute         |Unchanged - 02 |Second Unchanged   |
      |This is the first invalid comment      |Invalid              |WebCategoryDispute         |Invalid - 01   |First Invalid      |
      |This is the second invalid comment     |Invalid              |WebCategoryDispute         |Invalid - 02   |Second Invalid     |
      |This is the first fixed comment        |Fixed                |WebCategoryDispute         |Fixed - 01     |First Fixed        |
      |This is the second fixed comment       |Fixed                |WebCategoryDispute         |Fixed - 02     |Second Fixed       |
    Then I goto "escalations/webcat/complaints"
    And I should see "abc.com"
    And I should see "google.com"
    Then I click "#resolution_comment_button111"
    And element with id "entry-email-response-to-customers_111" should contain a value of "This is the first fixed comment"
    And I click "#entry-email-response-to-customers-select_111"
    Then I click element with tag "option" and text "Fixed - 02"
    #confirm textarea updates
