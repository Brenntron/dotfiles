Feature: WebRep Reputation Research

@javascript
  Scenario: a user goes to the Reputation Research page
  Given a user with role "webrep user" exists and is logged in
  And I go to "/escalations/webrep/research"
  And I fill in "search_uri" with "cisco.com"
  And I click "#submit-button"
  Then I wait for "30" seconds
  Then I should see "cisco.com (8 found)"
  Then I should see "ammssanfrancisco.com:80/ponyb/gate.php"
  Then I should see "www.cisco.com/web"
  Then I should see "callcisco.com"