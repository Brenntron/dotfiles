Feature: WebRep TMI Tab
  In order to view TMI dispute info as a user I will provide ways to view TMI info.

  Rule: Tag Managment Inteface is only displayed to tmi viewers and tmi managers

    @javascript
    Scenario: a user visits a disputs's show page without either the 'tmi viewer' or 'tmi manager' roles
      Given a user with role "webrep user" exists and is logged in
      And the following disputes exist and have entries:
        | id |
        | 1  |
      And a dispute exists and is related to disputes with ID, "1":
      When I go to "/escalations/webrep/disputes/1"
      And I wait for "2" seconds
      And I click "#context-tags-tab-link"
      Then I should see "ENRICHMENT SERVICE"
      And I should see "PREVALENCE"
      And I should not see "TAG MANAGEMENT INTERFACE"

    @javascript
    Scenario: a user visits a disputs's show page with the 'tmi viewer' role
      Given a webrep user with the role "tmi viewer" exists and is logged in
      And the following disputes exist and have entries:
        | id |
        | 1  |
      And a dispute exists and is related to disputes with ID, "1":
      When I go to "/escalations/webrep/disputes/1"
      And I wait for "2" seconds
      And I click "#context-tags-tab-link"
      Then I should see "ENRICHMENT SERVICE"
      And I should see "PREVALENCE"
      And I should see "TAG MANAGEMENT INTERFACE"

    @javascript
    Scenario: a user visits a disputs's show page with the 'tmi manager' role
      Given a webrep user with the role "tmi manager" exists and is logged in
      And the following disputes exist and have entries:
        | id |
        | 1  |
      And a dispute exists and is related to disputes with ID, "1":
      When I go to "/escalations/webrep/disputes/1"
      And I wait for "2" seconds
      And I click "#context-tags-tab-link"
      Then I should see "ENRICHMENT SERVICE"
      And I should see "PREVALENCE"
      And I should see "TAG MANAGEMENT INTERFACE"
