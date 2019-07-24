Feature: SHA Validations
  In order to ensure filerep disputes can be created correctly
  as a user
  I will validate submitted SHAs on the frontend

  @javascript
  Scenario: SHA with invalid characters should be rejected
    Given a user with role "filerep user" exists and is logged in
    And bugzilla rest api always saves
    And ThreatGrid API call is stubbed
    And Reversing Labs certificates API call is stubbed
    And Sandbox API call is stubbed
    And ReversingLabs API call is stubbed
    When I go to "/escalations/file_rep/disputes"
    And I click "#new-dispute"
    And I fill in "shas_list" with "I AM DUMMY TEXT"
    Then I click "#disposition_suggested"
    Then I should see "The following are not valid SHAs"

  @javascript
  Scenario: SHA that isn't long enough should be rejected
    Given a user with role "filerep user" exists and is logged in
    And bugzilla rest api always saves
    And ThreatGrid API call is stubbed
    And Reversing Labs certificates API call is stubbed
    And Sandbox API call is stubbed
    And ReversingLabs API call is stubbed
    When I go to "/escalations/file_rep/disputes"
    And I click "#new-dispute"
    And I fill in "shas_list" with "f95c7b907576e5e7b20daea3c2"
    Then I click "#disposition_suggested"
    Then I should see "The following are not valid SHAs"

  @javascript
  Scenario: a bad SHA among good SHAs should be rejected
    Given a user with role "filerep user" exists and is logged in
    And bugzilla rest api always saves
    And ThreatGrid API call is stubbed
    And Reversing Labs certificates API call is stubbed
    And Sandbox API call is stubbed
    And ReversingLabs API call is stubbed
    When I go to "/escalations/file_rep/disputes"
    And I click "#new-dispute"
    And I fill in "shas_list" with "a5454550d8122349f2eb73c5cc7aa414dc0eaf94732074b0472e30527ca3ea38 \n 5631651365204fce \n 2e1ac278d7d7570faf9e9a3af04d17b3e42d3ec9a6b2f3e52e13c504409a51b4"
    Then I click "#disposition_suggested"
    Then I should see "The following are not valid SHAs"