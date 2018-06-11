Feature: Webrep communications
  In order to communicate with customers
  I will provide a communications interface

  #TODO: we need to update the user role on these tests

  @javascript
  Scenario: there should be a difference between read and unread emails
  Given a user with role "admin" exists and is logged in

    And the following disputes exist:
      | id     |
      | 722    |
    And the following dispute emails exist:
      |id  | dispute_id           | status |
      | 1  | 722                  | unread |
      | 2  | 722                  | read   |
    And I goto "/escalations/webrep/disputes/722"
    And row with email_id "1" should have class "email-unread"
    And row with email_id "2" should have class "email-read"


  @javascript
  Scenario: an unread email should change to read once clicked
    Given a user with role "admin" exists and is logged in

    And the following disputes exist:
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
    Given a user with role "admin" exists and is logged in
    And the following disputes exist:
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
    Given a user with role "admin" exists and is logged in

    And the following disputes exist:
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
    Given a user with role "admin" exists and is logged in

    And the following disputes exist:
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



  ##Notes

  @javascript
  Scenario: a user can create a new note
    Given a user with role "admin" exists and is logged in

    And the following disputes exist:
      | id     |
      | 722    |
    And I goto "/escalations/webrep/disputes/722"
    Then I click "Add Note"
    And I fill in "new-case-note-textarea" with "I like jelly beans"
    Then I click ".new-case-note-save-button"
    And I wait for "2" seconds
    Then I should see "NOTE CREATED"


  @javascript
  Scenario: a user cannot edit a note authored by another user
    Given a user with role "admin" exists and is logged in
    And the following users exist
      |id  |cec_username|
      |2   | snorty     |

    And the following disputes exist:
      | id     |
      | 722    |
    And the following dispute comments exist:
      | id | dispute_id | comment                      |  user_id |
      |  1 |  722       | purple pigs are cool         |  2       |
      |  2 |  722       |  I prefer yellow pigs        |  1       |

    And I goto "/escalations/webrep/disputes/722"
    Then I click the note with text "purple pigs are cool"
    And I fill in "editable-note-block" with "I am editing stuff"
    When I click ".note-save-edit-button"
    Then I wait for "2" seconds
    Then I should see "NOTE COULD NOT BE UPDATED"


  @javascript
  Scenario: a user can edit their own note
    Given a user with role "admin" exists and is logged in
    And the following users exist
      |id  |cec_username|
      |2   | snorty     |

    And the following disputes exist:
      | id     |
      | 722    |
    And the following dispute comments exist:
      | id | dispute_id | comment                      |  user_id |
      |  1 |  722       | purple pigs are cool         |  2       |
      |  2 |  722       |  I prefer yellow pigs        |  1       |

    And I goto "/escalations/webrep/disputes/722"
    Then I click the note with text "I prefer yellow pigs"
    And I fill in "editable-note-block" with "I am editing stuff"
    When I click ".note-save-edit-button"
    Then I wait for "2" seconds
    Then I should see "NOTE UPDATED"



  @javascript
  Scenario: a user cannot delete a note authored by another user
    Given a user with role "admin" exists and is logged in
    And the following users exist
      |id  |cec_username|
      |2   | snorty     |

    And the following disputes exist:
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
    Given a user with role "admin" exists and is logged in
    And the following users exist
      |id  |cec_username|
      |2   | snorty     |

    And the following disputes exist:
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


