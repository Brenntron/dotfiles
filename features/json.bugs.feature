Feature: Bug
  In order to import, create or edit bugs
  from web services
  I will provides ways to interact with bugs


  # ==== Show Bug ====
  @javascript
  Scenario: The summary text should update with tag edits
#    Given I send and accept JSON
    Given a user exists
    And the following bugs exist:
      | id     | bugzilla_id | state | user_id | summary             | product  | component   | version | description       |
      | 121778 | 121778      | OPEN  | 1       | [BP][NSS] fixed bug | Research | Snort Rules | 2.6.0   | test description3 |
    When I send a GET request to "/api/v1/bugs/121778.json"
    Then response should have bug_id "121778"

#    Then I should see "[BP][NSS] fixed bug"
#    And  I fill in selectized with "TELUS"
#    Then the selectize field contains the text "TELUS"
#    And I should see "[TELUS] fixed bug"
#    Then I fill in selectized with "BP"
#    Then the selectize field contains the text "TELUSBP"
#    Then I should see "[TELUS][BP] fixed bug"
#    And I should not see "[BP][NSS] fixed bug"



