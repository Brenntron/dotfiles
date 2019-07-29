Feature: Send to Threatgrid
  In order to send a sample to Threatgrid
  as a user
  I will provide the Push to Threatgrid button on the filerep show page


  @javascript
  Scenario: A dispute with no threatgrid entry shows the 'send to threatgrid' button
    Given a user with role "filerep user" exists and is logged in
    And vrtincoming exists
    And the following customers exist:
      |id| name            |
      |1 | Dispute Analyst |
    And A FileRep Dispute with trait "not_in_threatgrid" exists
    Then I go to "/escalations/file_rep/disputes/1"
    # Dismiss error messages or else the Research tab won't be clickable
    Then I click "button.close"
    Then I click "#research-tab-link"
    Then I should see "PUSH SAMPLE TO THREATGRID"

  @javascript
  Scenario: Clicking the Send to Threatgrid button sends the sample to Threatgrid
    Given a user with role "filerep user" exists and is logged in
    And vrtincoming exists
    And the following customers exist:
      |id| name            |
      |1 | Dispute Analyst |
    And A FileRep Dispute with trait "not_in_threatgrid" exists
    Then I go to "/escalations/file_rep/disputes/1"
    # Dismiss error messages or else the Research tab won't be clickable
    Then I click "button.close"
    Then I click "#research-tab-link"
    Then I click "send-to-threatgrid"
    Then I should see "SAMPLE SUCCESSFULLY SENT TO THREATGRID"