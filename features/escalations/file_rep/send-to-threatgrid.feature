Feature: Send to Threatgrid
  In order to send a sample to Threatgrid
  as a user
  I will provide the Push to Threatgrid button on the filerep show page


  @javascript
  Scenario: a user visits a FileRep Dispute Show Page and confirms that the layout is properly rendered
    Given a user with role "filerep user" exists and is logged in
    And vrtincoming exists
    And A FileRep Dispute with trait "default" exists
    Then I go to "/escalations/file_rep/disputes/1"
#    And I wait for "25" seconds
    Then I should see "PUSH SAMPLE TO THREATGRID"