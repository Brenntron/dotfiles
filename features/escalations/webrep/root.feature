Feature: Webrep Root
  Features in the Webrep Root Controller

  @javascript
  Scenario: The webrep root redirects to webrep/tickets
    Given a user with role "webrep user" exists and is logged in
    When I goto "/escalations/webrep"
    Then I should see "/escalations/webrep/disputes" in the current url

