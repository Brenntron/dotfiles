Feature: Webcat resolution template manager

  Background:
    Given a guest company exists

  @javascript
  Scenario: A user with 'webcat user' permissions can only view existing resolution templates
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
    Then I go to "/escalations/webcat/resolution_message_templates"
    And I should not see "New Resolution Templates"
    And the table "resolution-message-templates-table" should have "6" number of rows
    And I should not see element with class "manage-response-delete-icon"
    And I click first element of class ".edit-resolution-message-template"
    And I should see element "#editResolutionMessageTemplatesDialog"
    And I should not see "#create-resolution-template-name"
    And I should not see "#create-resolution-template-description"
    And I should not see "#create-resolution-template-message"
    And I should not see "#create-resolution-template-submit"
    And I click button "update-resolution-template-close"
    And I should not see element "#editResolutionMessageTemplatesDialog"

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
    And I should see "RESOLUTION MESSAGE TEMPLATE CREATED"
    And I wait for "4" seconds
    And the table "resolution-message-templates-table" should have "7" number of rows

  @javascript
  Scenario: A user with ‘webcat manager’ permissions can edit a webcat resolution message template
    Given a user with role "webcat manager" exists and is logged in
    And the following complaint entries exist:
      | id  | uri            | domain          | entry_type | status |
      | 111 | abc.com        | abc.com         | URI/DOMAIN | NEW    |
    And the following resolution message templates exist:
      |body                                   |resolution_type      |ticket_type                |name               |description                  |
      |This is the first fixed comment        |Fixed                |WebCategoryDispute         |Name goes here     |Description goes here        |
    Then I go to "/escalations/webcat/resolution_message_templates"
    And the table "resolution-message-templates-table" should have "1" number of rows
    And I should see "Description goes here"
    And I should see "Name goes here"
    And I should see "Fixed"
    And I click first element of class ".edit-resolution-message-template"
    And I should see element "#editResolutionMessageTemplatesDialog"
    Then I click "#update-form_resolution_type"
    Then I click element with tag "option" and text "Invalid"
    Then I fill in element, "#update-resolution-template-name" with "New name"
    Then I fill in element, "#update-resolution-template-description" with "New description"
    Then I fill in element, "#update-resolution-template-message" with "New body message"
    Then I click button "update-resolution-template-submit"
    Then I should see "RESOLUTION MESSAGE TEMPLATE UPDATED"
    #confirm table has updated
    And I wait for "4" seconds
    And I should see "New name"
    And I should see "New description"
    And I should see "Invalid"
    #confirm edit modal has updated
    And I click first element of class ".edit-resolution-message-template"
    And element with id "update-resolution-template-name" should contain a value of "New name"
    And element with id "update-resolution-template-description" should contain a value of "New description"
    And element with id "update-resolution-template-message" should contain a value of "New body message"

  @javascript
  Scenario: A user with ‘webcat manager’ permissions can delete a webcat resolution message template
    Given a user with role "webcat manager" exists and is logged in
    And the following complaint entries exist:
      | id  | uri            | domain          | entry_type | status |
      | 111 | abc.com        | abc.com         | URI/DOMAIN | NEW    |
    And the following resolution message templates exist:
      |body                                   |resolution_type      |ticket_type                |name           |description        |
      |This is the first fixed comment        |Fixed                |WebCategoryDispute         |Fixed - 01     |First Fixed        |
      |This is the second fixed comment       |Fixed                |WebCategoryDispute         |Fixed - 02     |Second Fixed       |
    Then I go to "/escalations/webcat/resolution_message_templates"
    And the table "resolution-message-templates-table" should have "2" number of rows
    And I click first element of class ".manage-response-delete-icon"
    And I should see "ARE YOU SURE YOU WANT TO DELETE THIS TEMPLATE?"
    And I click button with class "confirm"
    And I wait for "4" seconds
    And the table "resolution-message-templates-table" should have "1" number of rows

  @javascript
  Scenario: A user with ‘webcat manager’ permissions can open and close the various modals
    Given a user with role "webcat manager" exists and is logged in
    And the following complaint entries exist:
      | id  | uri            | domain          | entry_type | status |
      | 111 | abc.com        | abc.com         | URI/DOMAIN | NEW    |
    And the following resolution message templates exist:
      |body                                   |resolution_type      |ticket_type                |name           |description        |
      |This is the first fixed comment        |Fixed                |WebCategoryDispute         |Fixed - 01     |First Fixed        |
    Then I go to "/escalations/webcat/resolution_message_templates"
    #Add new template
    Then I click button with class "add-message-template"
    And I should see element "#createResolutionMessageTemplatesDialog"
    Then I click "#create-resolution-template-cancel"
    And I should not see element "#createResolutionMessageTemplatesDialog"
    #Edit template
    And I click first element of class ".edit-resolution-message-template"
    And I should see element "#editResolutionMessageTemplatesDialog"
    Then I click "#update-resolution-template-cancel"
    And I should not see element "#editResolutionMessageTemplatesDialog"
    #Delete template
    And I click first element of class ".manage-response-delete-icon"
    And I should see "ARE YOU SURE YOU WANT TO DELETE THIS TEMPLATE?"
    And I click button with class "cancel"
    And I should not see "ARE YOU SURE YOU WANT TO DELETE THIS TEMPLATE?"

###  webcat index table actions ###

#  @javascript
#  Scenario: A user can load the resolution templates using the actions in the bulk resolution tool
#    Given a user with role "webcat user" exists and is logged in
#
#  @javascript
#  Scenario: A user can load the resolution templates using the actions in the resolution column
#    Given a user with role "webcat user" exists and is logged in
#    And the following complaint entries exist:
#      | id  | uri            | domain          | entry_type | status |
#      | 111 | abc.com        | abc.com         | URI/DOMAIN | NEW    |
#      | 222 | google.com     | google.com      | URI/DOMAIN | NEW    |
#    And the following resolution message templates exist:
#      |body                                   |resolution_type      |ticket_type                |name           |description        |
#      |This is the first unchanged comment    |Unchanged            |WebCategoryDispute         |Unchanged - 01 |First Unchanged    |
#      |This is the second unchanged comment   |Unchanged            |WebCategoryDispute         |Unchanged - 02 |Second Unchanged   |
#      |This is the first invalid comment      |Invalid              |WebCategoryDispute         |Invalid - 01   |First Invalid      |
#      |This is the second invalid comment     |Invalid              |WebCategoryDispute         |Invalid - 02   |Second Invalid     |
#      |This is the first fixed comment        |Fixed                |WebCategoryDispute         |Fixed - 01     |First Fixed        |
#      |This is the second fixed comment       |Fixed                |WebCategoryDispute         |Fixed - 02     |Second Fixed       |
#    Then I goto "escalations/webcat/complaints"
#    And I should see "abc.com"
#    And I should see "google.com"
#    Then I click "#resolution_comment_button111"
#    And element with id "entry-email-response-to-customers_111" should contain a value of "This is the first fixed comment"
#    And I click "#entry-email-response-to-customers-select_111"
#    Then I click element with tag "option" and text "Fixed - 02"
    #confirm textarea updates
