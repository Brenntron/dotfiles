Feature: Webcat convert entry to webrep dispute


  #*********************************************#

# Converting Webcat ticket to Webrep (WEB-4413)
#  only tickets from talos-intelligence are allowed to be converted - test from ti and from other sources
#  only tickets in an 'open' state are allowed to be converted - test each open and closed state
#  only one ticket can be converted at a time
#  ticket conversion should display all affected entries of the parent ticket
#  ticket conversion should display the summary supplied by the customer


  @javascript
  Scenario: a user tries to convert a webcat ticket that originated from WBNP and cannot
    Given a user with role "webcat user" exists and is logged in
    And the following complaints exist:
      | id | description         | ticket_source | channel | status |
      | 1  | this is shenanigans | RuleUI        | wbnp    | NEW    |
    And the following complaint entries exist:
      | id    | uri                | domain             | entry_type | complaint_id | status     |
      | 1111  | cashmeoutside.com  | cashmeoutside.com  | URI/DOMAIN |  1           | NEW        |
    And I goto "/escalations/webcat/complaints"
    Then I wait for "3" seconds
    And  I click row with id "1111"
    And Element with id "1111" should have class "selected"
    And I wait for "2" seconds
    And I click "#convert-ticket-button"
    And I wait for "1" seconds
    And I should see "TICKET CANNOT BE CONVERTED"
    And I should see "Selected ticket is not a customer ticket from talos-intelligence"

  @javascript
  Scenario: a user tries to convert a webcat ticket that was created internally via ACE and cannot
    Given a user with role "webcat user" exists and is logged in
    And the following complaints exist:
      | id | description         | ticket_source | channel  | status |
      | 1  | this is shenanigans |               | internal | NEW    |
    And the following complaint entries exist:
      | id    | uri                | domain             | entry_type | complaint_id | status     |
      | 1111  | cashmeoutside.com  | cashmeoutside.com  | URI/DOMAIN |  1           | NEW        |
    And I goto "/escalations/webcat/complaints"
    Then I wait for "3" seconds
    And  I click row with id "1111"
    And Element with id "1111" should have class "selected"
    And I wait for "2" seconds
    And I click "#convert-ticket-button"
    And I wait for "1" seconds
    And I should see "TICKET CANNOT BE CONVERTED"
    And I should see "Selected ticket is not a customer ticket from talos-intelligence"

  @javascript
  Scenario: a user tries to convert a webcat ticket that originated from the talos intelligence form
  and does not see an error msg
    Given a user with role "webcat user" exists and is logged in
    And the following complaints exist:
      | id | description         | ticket_source        | channel    | status |
      | 1  | this is shenanigans | talos-intelligence   | talosintel | NEW    |
    And the following complaint entries exist:
      | id    | uri                | domain             | entry_type | complaint_id | status     | ip_address |
      | 1111  | cashmeoutside.com  | cashmeoutside.com  | URI/DOMAIN |  1           | NEW        |            |
    And I goto "/escalations/webcat/complaints"
    Then I wait for "3" seconds
    And  I click row with id "1111"
    And Element with id "1111" should have class "selected"
    And I wait for "2" seconds
    And I click "#convert-ticket-button"
    And I wait for "1" seconds
    And I should not see "TICKET CANNOT BE CONVERTED"

  @javascript
  Scenario: a user tries to convert a webcat ticket that has a 'COMPLETED' status and cannot
    Given a user with role "webcat user" exists and is logged in
    And the following complaints exist:
      | id | description         | ticket_source        | channel    | status    |
      | 1  | this is shenanigans | talos-intelligence   | talosintel | COMPLETED |
    And the following complaint entries exist:
      | id    | uri                | domain             | entry_type | complaint_id | status     | ip_address |
      | 1111  | cashmeoutside.com  | cashmeoutside.com  | URI/DOMAIN |  1           | COMPLETED  |            |
    And I goto "/escalations/webcat/complaints"
    Then I wait for "3" seconds
    And  I click row with id "1111"
    And Element with id "1111" should have class "selected"
    And I wait for "2" seconds
    And I click "#convert-ticket-button"
    And I wait for "1" seconds
    And I should see "TICKET CANNOT BE CONVERTED"
    And I should see "Selected entry's parent ticket is not in a convertible (open) status."

  @javascript
  Scenario: a user tries to convert a webcat ticket that has a 'RESOLVED' status and cannot
    Given a user with role "webcat user" exists and is logged in
    And the following complaints exist:
      | id | description         | ticket_source        | channel    | status   |
      | 1  | this is shenanigans | talos-intelligence   | talosintel | RESOLVED |
    And the following complaint entries exist:
      | id    | uri                | domain             | entry_type | complaint_id | status    | ip_address |
      | 1111  | cashmeoutside.com  | cashmeoutside.com  | URI/DOMAIN |  1           | RESOLVED  |            |
    And I goto "/escalations/webcat/complaints"
    Then I wait for "3" seconds
    And  I click row with id "1111"
    And Element with id "1111" should have class "selected"
    And I wait for "2" seconds
    And I click "#convert-ticket-button"
    And I wait for "1" seconds
    And I should see "TICKET CANNOT BE CONVERTED"
    And I should see "Selected entry's parent ticket is not in a convertible (open) status."

  @javascript
  Scenario: a user tries to convert a webcat ticket that has an 'ACTIVE' status and does not get an error message
    Given a user with role "webcat user" exists and is logged in
    And the following complaints exist:
      | id | description         | ticket_source        | channel    | status |
      | 1  | this is shenanigans | talos-intelligence   | talosintel | ACTIVE |
    And the following complaint entries exist:
      | id    | uri                | domain             | entry_type | complaint_id | status    | ip_address |
      | 1111  | cashmeoutside.com  | cashmeoutside.com  | URI/DOMAIN |  1           | ASSIGNED  |            |
    And I goto "/escalations/webcat/complaints"
    Then I wait for "3" seconds
    And  I click row with id "1111"
    And Element with id "1111" should have class "selected"
    And I wait for "2" seconds
    And I click "#convert-ticket-button"
    And I wait for "1" seconds
    And I should not see "TICKET CANNOT BE CONVERTED"

  @javascript
  Scenario: a user tries to convert a webcat ticket that has a 'REOPENED' status and does not get an error message
    Given a user with role "webcat user" exists and is logged in
    And the following complaints exist:
      | id | description         | ticket_source        | channel    | status   |
      | 1  | this is shenanigans | talos-intelligence   | talosintel | REOPENED |
    And the following complaint entries exist:
      | id    | uri                | domain             | entry_type | complaint_id | status    | ip_address |
      | 1111  | cashmeoutside.com  | cashmeoutside.com  | URI/DOMAIN |  1           | REOPENED  |            |
    And I goto "/escalations/webcat/complaints"
    Then I wait for "3" seconds
    And  I click row with id "1111"
    And Element with id "1111" should have class "selected"
    And I wait for "2" seconds
    And I click "#convert-ticket-button"
    And I wait for "1" seconds
    And I should not see "TICKET CANNOT BE CONVERTED"

  @javascript
  Scenario: a user tries to convert a webcat ticket with multiple entries
  should see all entries listed in the conversion dropdown
    Given a user with role "webcat user" exists and is logged in
    And the following complaints exist:
      | id | description         | ticket_source        | channel    | status |
      | 1  | this is shenanigans | talos-intelligence   | talosintel | ACTIVE |
    And the following complaint entries exist:
      | id    | uri                | domain             | entry_type | complaint_id | status    | ip_address |
      | 1111  | cashmeoutside.com  | cashmeoutside.com  | URI/DOMAIN |  1           | ASSIGNED  |            |
      | 2222  | howbowda.com       | howbowda.com       | URI/DOMAIN |  1           | ASSIGNED  |            |
      | 3333  | hideyokids.com     | hideyokids.com     | URI/DOMAIN |  1           | ASSIGNED  |            |
    And I goto "/escalations/webcat/complaints"
    Then I wait for "3" seconds
    And  I click row with id "1111"
    And I click "#convert-ticket-button"
    And I wait for "1" seconds
    And Table with id "entries-to-convert" should have "3" number of rows


####    End ticket conversion tests