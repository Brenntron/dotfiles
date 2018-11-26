Feature: Dispute permissions


#  webrep_user permissions
  @javascript
  Scenario: A webrep user can take or reassign a dispute
    Given a user with role "webrep user" exists and is logged in
    Given the following unassigned disputes exist:
    |id|
    |1 |
    And I go to "/escalations/webrep/disputes/1"
    Then I wait for "2" seconds
    Then I should see "Unassigned"
    Then I should see button with class "take-ticket-button"
    Then I should see button with class "ticket-owner-button"

  @javascript
  Scenario: A webrep user can change the status of a dispute
    Given a user with role "webrep user" exists and is logged in
    Given the following unassigned disputes exist:
      |id|
      |1 |
    And I go to "/escalations/webrep/disputes/1"
    Then I should see button with class "ticket-status-button"

#  make sure people with no permissions can't do these things
  @javascript
  Scenario: An admin can not take or reassign a dispute
    Given a user with role "admin" exists and is logged in
    Given the following unassigned disputes exist:
      |id|
      |1 |
    And I go to "/escalations/webrep/disputes/1"
    Then I should not see button with class "take-ticket-button"
    Then I should not see button with class "ticket-owner-button"



  @javascript
  Scenario: Non webrep user can not take or reassign a dispute
    Given a user with role "analyst" exists and is logged in
    Given the following unassigned disputes exist:
      |id|
      |1 |
    And I go to "/escalations/webrep/disputes/1"
    Then I should see "You are not authorized"


  @javascript
  Scenario: Non webrep user can not take or reassign a dispute
    Given a user with role "build coordinator" exists and is logged in
    Given the following unassigned disputes exist:
      |id|
      |1 |
    And I go to "/escalations/webrep/disputes/1"
    Then I should see "You are not authorized"


  @javascript
  Scenario: Non webrep user can not take or reassign a dispute
    Given a user with role "committer" exists and is logged in
    Given the following unassigned disputes exist:
      |id|
      |1 |
    And I go to "/escalations/webrep/disputes/1"
    Then I should see "You are not authorized"


  @javascript
  Scenario: Non webrep user can not take or reassign a dispute
    Given a user with role "manager" exists and is logged in
    Given the following unassigned disputes exist:
      |id|
      |1 |
    And I go to "/escalations/webrep/disputes/1"
    Then I should see "You are not authorized"


  @javascript
  Scenario: Non webrep user can not take or reassign a dispute
    Given a user with role "api user" exists and is logged in
    Given the following unassigned disputes exist:
      |id|
      |1 |
    And I go to "/escalations/webrep/disputes/1"
    Then I should see "You are not authorized"


  @javascript
  Scenario: Non webrep user can not take or reassign a dispute
    Given a user with role "ips escalator" exists and is logged in
    Given the following unassigned disputes exist:
      |id|
      |1 |
    And I go to "/escalations/webrep/disputes/1"
    Then I should see "You are not authorized"
