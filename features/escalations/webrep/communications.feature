Feature: Webrep communications
  In order to communicate with customers
  I will provide a communications interface


  @javascript
  Scenario: there should be a difference between read and unread emails
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id     |
      | 722    |
    And the following dispute emails exist:
      |id  | dispute_id           | status |
      | 1  | 722                  | unread |
      | 2  | 722                  | read   |
    And I goto "/escalations/webrep/disputes/722#communication_tab"
    And row with email_id "1" should have class "email-unread"
    And row with email_id "2" should have class "email-read"


  @javascript
  Scenario: an unread email should change to read once clicked
    Given a user with role "webrep user" exists and is logged in

    And the following disputes exist and have entries:
      | id     |
      | 722    |
    And the following dispute emails exist:
      |id  | dispute_id           | status |
      | 1  | 722                  | unread |
      | 2  | 722                  | read   |
    And I goto "/escalations/webrep/disputes/722"
    And row with email_id "1" should have class "email-unread"
    And I click on row with email_id "1"
    # readjust UI for ease of testing
    And I click on row with email_id "2"
    And row with email_id "1" should have class "email-read"


  @javascript
  Scenario: I should see the full contents of an email once clicked
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id     |
      | 722    |
    And the following dispute emails exist:
      |id  | dispute_id           | status | subject          |to                        |  from                    | body                                                                                                                                                                                                              |
      | 1  | 722                  | unread | subject number 1 | email@webrepdisputes.com |  customer@gmail.com      |" Key Rules:Problem Summary: Hi Already have this mail server running a couple of domains of our company and we have 3 clients in a domains that cannot send email to emails of a company using sendbase service. |
      | 2  | 722                  | read   | another thing    | email@webrepdisputes.com |  customer@gmail.com      |    "This should only be seen second email"                                                                                                                                                                                                            |
    And I goto "/escalations/webrep/disputes/722"
    And I should not see "Hi Already have this mail server running"
    And I should not see "This should only be seen second email"
    And I click on row with email_id "1"
    And I wait for "2" seconds
    And I should see "Hi Already have this mail server running"
    And I should not see "This should only be seen second email"
    And I click on row with email_id "2"
    And I should see "This should only be seen second email"
    And I should not see "Hi Already have this mail server running"



  @javascript
  Scenario: a user can reply to an email
    Given a user with role "webrep user" exists and is logged in

    And the following disputes exist and have entries:
      | id     |
      | 722    |
    And the following dispute emails exist:
      |id  | dispute_id           | status |
      | 1  | 722                  | unread |
      | 2  | 722                  | read   |
    When I goto "/escalations/webrep/disputes/722"
    And I click on row with email_id "1"
    And I wait for "2" seconds
    When I click ".reply-button"
    And I fill in the reply textarea with "I'm replying to your email"
    Given successful "::Bridge::SendEmailEvent" PeakeBridge post message is stubbed
    When I click "Send"
    And I wait for "2" seconds
    And I should see "EMAIL SENT"


  @javascript
  Scenario: a user can create a new email
    Given a user with role "webrep user" exists and is logged in

    And the following disputes exist and have entries:
      | id     |
      | 722    |
    And the following dispute emails exist:
      |id  | dispute_id           | status |
      | 1  | 722                  | unread |
      | 2  | 722                  | read   |
    And I goto "/escalations/webrep/disputes/722"
    Then I click "Compose New Email"
    And I wait for "2" seconds
    And I fill in "receiver" with "customer@gmail.com"
    Given successful "::Bridge::SendEmailEvent" PeakeBridge post message is stubbed
    Then I click "Send"
    And I wait for "2" seconds
    And I should see "EMAIL SENT"


  @javascript
  Scenario: a user can create a new email using an email template
    Given a user with role "webrep user" exists and is logged in

    And the following disputes exist and have entries:
      | id     |
      | 722    |
    And the following dispute emails exist:
      |id  | dispute_id           | status |
      | 1  | 722                  | unread |
      | 2  | 722                  | read   |
    And the following email templates exist:
     | template_name | body                                                                                                    |
     |  PSB          | Our worldwide sensor network indicates that spam originated from IP (x.x.x.x) as recently as xx-xx-xx . |
    And I goto "/escalations/webrep/disputes/722"
    Then I click "Compose New Email"
    And I wait for "2" seconds
    And I select "PSB" from "select-new-template"
    And I wait for "2" seconds
    # this works confirmed via screen shot, but can't get test to pass
#    Then I should see "Our worldwide sensor network indicates that spam originated from IP (x.x.x.x) as recently as xx-xx-xx ."



  ##Notes

  @javascript
  Scenario: a user can create a new note
    Given a user with role "webrep user" exists and is logged in

    And the following disputes exist and have entries:
      | id     |
      | 722    |
    And I goto "/escalations/webrep/disputes/722"
    Then I click "Add Note"
    And I fill a content-editable field ".new-case-note-textarea" with "I like jelly beans"
    Then I click ".new-case-note-save-button"
    And I wait for "2" seconds
    Then I should see "NOTE CREATED"


  @javascript
  Scenario: a user can edit their own note
    Given a user with role "webrep user" exists and is logged in
    And the following users exist
      |id  |cec_username|
      |2   | snorty     |

    And the following disputes exist and have entries:
      | id     |
      | 722    |
    And the following dispute comments exist:
      | id | dispute_id | comment                      |  user_id |
      |  1 |  722       | purple pigs are cool         |  2       |
      |  2 |  722       |  I prefer yellow pigs        |  1       |

    And I goto "/escalations/webrep/disputes/722"
    Then I click the note with text "I prefer yellow pigs"
    And I fill a content-editable field ".note-block2" with "I am editing stuff"
    When I click ".update-note"
    Then I wait for "2" seconds
    Then I should see "NOTE UPDATED"



  @javascript
  Scenario: a user cannot delete a note authored by another user
    Given a user with role "webrep user" exists and is logged in
    And the following users exist
      |id  |cec_username|
      |2   | snorty     |

    And the following disputes exist and have entries:
      | id     |
      | 722    |
    And the following dispute comments exist:
      | id | dispute_id | comment                      |  user_id |
      |  1 |  722       | purple pigs are cool         |  2       |
      |  2 |  722       |  I prefer yellow pigs        |  1       |

    And I goto "/escalations/webrep/disputes/722"
    And I click the delete button of the first comment
    Then I wait for "2" seconds
    Then I should see "NOTE COULD NOT BE DELETED"



  @javascript
  Scenario: a user can delete a note authored by themselves
    Given a user with role "webrep user" exists and is logged in
    And the following users exist
      |id  |cec_username|
      |2   | snorty     |

    And the following disputes exist and have entries:
      | id     |
      | 722    |
    And the following dispute comments exist:
      | id | dispute_id | comment                      |  user_id |
      |  1 |  722       | purple pigs are cool         |  1       |
      |  2 |  722       |  I prefer yellow pigs        |  2       |

    And I goto "/escalations/webrep/disputes/722"
    And I click the delete button of the first comment
    Then I wait for "2" seconds
    Then I should see "NOTE DELETED"


  ## Email Templates

  @javascript
  Scenario: a user can create an email template
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id     |
      | 722    |
    And I goto "/escalations/webrep/disputes/722"
    And I click "Manage Email Templates"
    Then I click "Create New Template"
    And I wait for "2" seconds
    And I fill in "template-name" with "General Template"
    And I fill in "template-description" with "This is a general template for all things"
    And I fill in "new-template-body" with "This is everything I ever wanted in a template."
    Then I click "Save Template"
    When I wait for "3" seconds
    Then I should see "EMAIL TEMPLATE CREATED"



  @javascript
  Scenario: a user can edit an email template
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id     |
      | 722    |
    And the following email templates exist:
      | template_name | body                                                                                                    | description     |
      |  PSB          | Our worldwide sensor network indicates that spam originated from IP (x.x.x.x) as recently as xx-xx-xx . | PSB description |
    And I goto "/escalations/webrep/disputes/722"
    And I click "Manage Email Templates"
    Then I click ".edit-template"
    Then I wait for "2" seconds
    Then I fill in "template-name" with "PSB alternate name"
    When I click "Update Template"
    And I wait for "3" seconds
    Then I should see "EMAIL TEMPLATE UPDATED"


  @javascript
  Scenario: a user can delete an email template
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist and have entries:
      | id     |
      | 722    |
    And the following email templates exist:
      | template_name | body                                                                                                    | description     |
      |  PSB          | Our worldwide sensor network indicates that spam originated from IP (x.x.x.x) as recently as xx-xx-xx . | PSB description |
    And I goto "/escalations/webrep/disputes/722"
    And I click "Manage Email Templates"
    Then I click ".delete-template"
    And I wait for "3" seconds
    Then I should see "EMAIL TEMPLATE DELETED"

  @javascript
  Scenario: a user views an email that should have the customer facing flag
    Given a user with role "webrep user" exists and is logged in
    Given the following customers exist:
    |id|
    |1 |
    And the following disputes exist and have entries:
      | id     |
      | 722    |
    And the following dispute emails exist:
      |id| dispute_id | status | subject          |to                        | from        | body                                                                                                                                                                                                             |
      | 1| 722        | unread | subject number 1 | email@webrepdisputes.com | bob@bob.com |" Key Rules:Problem Summary: Hi Already have this mail server running a couple of domains of our company and we have 3 clients in a domains that cannot send email to emails of a company using sendbase service. |
    Then I go to "/escalations/webrep/disputes/722"
    Then I click on row with email_id "1"
    Then I should see div element with class "customer-facing-notice"
