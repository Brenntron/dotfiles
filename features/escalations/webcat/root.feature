Feature: Webcat Root
  Features in the Webcat Root Controller

  @javascript
  Scenario: The webcat root redirects to webcat/complaints
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat"
    Then I should see "/escalations/webcat/complaints" in the current url

