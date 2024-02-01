Feature: Webcat index filters

  @javascript
  Scenario: a user selects the 'My Tickets' filter and does not see complaints assigned to other users
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type |  status     | user_id|
      |  1 | abc.com        | abc.com         | URI/DOMAIN |  ASSIGNED   |    1   |
      |  2 | whatever.com   | whatever.com    | URI/DOMAIN |  ASSIGNED   |    2   |
      |  3 | url.com        | url.com         | URI/DOMAIN |  ASSIGNED   |    3   |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I should see "abc.com"
    And I should see "whatever.com"
    And I should see "url.com"
    And I click "#filter-complaints"
    And I wait for "2" seconds
    And I click "My Tickets"
    Then I wait for "6" seconds
    Then I should see "abc.com"
    And I should not see "whatever.com"
    And I should not see "url.com"

  @javascript
  Scenario: a user selects the 'My Tickets' filter and does not see complaints that are unassigned
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type |  status     | user_id|
      |  1 | abc.com        | abc.com         | URI/DOMAIN |  ASSIGNED   |    1   |
      |  2 | whatever.com   | whatever.com    | URI/DOMAIN |  NEW        |        |
      |  3 | url.com        | url.com         | URI/DOMAIN |  NEW        |        |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I should see "abc.com"
    And I should see "whatever.com"
    And I should see "url.com"
    And I click "#filter-complaints"
    And I wait for "2" seconds
    And I click "My Tickets"
    Then I wait for "6" seconds
    Then I should see "abc.com"
    And I should not see "whatever.com"
    And I should not see "url.com"

  @javascript
  Scenario: a user selects the 'My Tickets' filter and sees their open and completed tickets
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type |  status     | user_id |
      |  1 | abc.com        | abc.com         | URI/DOMAIN |  ASSIGNED   |    1    |
      |  2 | whatever.com   | whatever.com    | URI/DOMAIN |  PENDING    |    1    |
      |  3 | url.com        | url.com         | URI/DOMAIN |  COMPLETED  |    1    |
      |  4 | gurl.com       | gurl.com        | URI/DOMAIN |  NEW        |         |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I should see "abc.com"
    And I should see "whatever.com"
    And I should see "url.com"
    And I should see "gurl.com"
    And I click "#filter-complaints"
    And I wait for "2" seconds
    And I click "My Tickets"
    Then I wait for "6" seconds
    Then I should see "abc.com"
    And I should see "whatever.com"
    And I should see "url.com"
    And I should not see "gurl.com"

  @javascript
  Scenario: a user selects the 'My Open Tickets' filter and does not see complaints assigned to other users
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type |  status     | user_id|
      |  1 | abc.com        | abc.com         | URI/DOMAIN |  ASSIGNED   |    1   |
      |  2 | whatever.com   | whatever.com    | URI/DOMAIN |  ASSIGNED   |    2   |
      |  3 | url.com        | url.com         | URI/DOMAIN |  ASSIGNED   |    3   |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I should see "abc.com"
    And I should see "whatever.com"
    And I should see "url.com"
    And I click "#filter-complaints"
    And I wait for "2" seconds
    And I click "My Open Tickets"
    Then I wait for "6" seconds
    Then I should see "abc.com"
    And I should not see "whatever.com"
    And I should not see "url.com"

  @javascript
  Scenario: a user selects the 'My Open Tickets' filter and does not see complaints that are unassigned
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type |  status     | user_id|
      |  1 | abc.com        | abc.com         | URI/DOMAIN |  ASSIGNED   |    1   |
      |  2 | whatever.com   | whatever.com    | URI/DOMAIN |  NEW        |        |
      |  3 | url.com        | url.com         | URI/DOMAIN |  NEW        |        |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I should see "abc.com"
    And I should see "whatever.com"
    And I should see "url.com"
    And I click "#filter-complaints"
    And I wait for "2" seconds
    And I click "My Open Tickets"
    Then I wait for "6" seconds
    Then I should see "abc.com"
    And I should not see "whatever.com"
    And I should not see "url.com"

  @javascript
  Scenario: a user selects the 'My Open Complaints' filter and does not see their completed tickets
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type |  status     | user_id |
      |  1 | abc.com        | abc.com         | URI/DOMAIN |  ASSIGNED   |    1    |
      |  2 | whatever.com   | whatever.com    | URI/DOMAIN |  PENDING    |    1    |
      |  3 | purl.com       | purl.com        | URI/DOMAIN |  COMPLETED  |    1    |
      |  4 | gurl.com       | gurl.com        | URI/DOMAIN |  COMPLETED  |    1    |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I should see "abc.com"
    And I should see "whatever.com"
    And I should see "purl.com"
    And I should see "gurl.com"
    And I click "#filter-complaints"
    And I wait for "2" seconds
    And I click "My Open Tickets"
    Then I wait for "6" seconds
    Then I should see "abc.com"
    And I should see "whatever.com"
    And I should not see "purl.com"
    And I should not see "gurl.com"


  @javascript
  Scenario: a user selects the 'My Closed Tickets' filter and does not see complaints assigned to other users
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type |  status     | user_id|
      |  1 | abc.com        | abc.com         | URI/DOMAIN |  COMPLETED  |    1   |
      |  2 | whatever.com   | whatever.com    | URI/DOMAIN |  ASSIGNED   |    2   |
      |  3 | url.com        | url.com         | URI/DOMAIN |  COMPLETED  |    3   |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I should see "abc.com"
    And I should see "whatever.com"
    And I should see "url.com"
    And I click "#filter-complaints"
    And I wait for "2" seconds
    And I click "My Closed Tickets"
    Then I wait for "6" seconds
    Then I should see "abc.com"
    And I should not see "whatever.com"
    And I should not see "url.com"

  @javascript
  Scenario: a user selects the 'My Close Complaints' filter and does not see their open tickets
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type |  status     | user_id |
      |  1 | abc.com        | abc.com         | URI/DOMAIN |  ASSIGNED   |    1    |
      |  2 | whatever.com   | whatever.com    | URI/DOMAIN |  PENDING    |    1    |
      |  3 | purl.com       | purl.com        | URI/DOMAIN |  COMPLETED  |    1    |
      |  4 | gurl.com       | gurl.com        | URI/DOMAIN |  COMPLETED  |    1    |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I should see "abc.com"
    And I should see "whatever.com"
    And I should see "purl.com"
    And I should see "gurl.com"
    And I click "#filter-complaints"
    And I wait for "2" seconds
    And I click "My Closed Tickets"
    Then I wait for "6" seconds
    Then I should not see "abc.com"
    And I should not see "whatever.com"
    And I should see "purl.com"
    And I should see "gurl.com"

  @javascript
  Scenario: a user selects the 'New Tickets' filter and only sees tickets with status NEW
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type |  status     | user_id |
      |  1 | abc.com        | abc.com         | URI/DOMAIN |  ASSIGNED   |    1    |
      |  2 | whatever.com   | whatever.com    | URI/DOMAIN |  PENDING    |    1    |
      |  3 | purl.com       | purl.com        | URI/DOMAIN |  NEW        |         |
      |  4 | gurl.com       | gurl.com        | URI/DOMAIN |  COMPLETED  |    1    |
      |  5 | twirl.com      | twirl.com       | URI/DOMAIN |  NEW        |         |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I should see "abc.com"
    And I should see "whatever.com"
    And I should see "purl.com"
    And I should see "gurl.com"
    And I should see "twirl.com"
    And I click "#filter-complaints"
    And I wait for "2" seconds
    And I click "New Tickets"
    Then I wait for "6" seconds
    Then I should not see "abc.com"
    And I should not see "whatever.com"
    And I should see "purl.com"
    And I should not see "gurl.com"
    And I should see "twirl.com"

  # TODO - New Talos Tickets, New WBRS Tickets, New Internal Tickets
  # Scenario: a user selects the 'New Talos Tickets' and does not see internal tickets or tickets from WBRS
  # Scenario: a user selects the 'New Talos Tickets' and does not see closed tickets from Talos
  # Scenario: a user selects the 'New Talos Tickets' and does not see in progress tickets from Talos
  # Scenario: a user selects the 'New WBRS Tickets' and does not see internal tickets or tickets from Talos
  # Scenario: a user selects the 'New WBRS Tickets' and does not see closed tickets from WBRS
  # Scenario: a user selects the 'New WBRS Tickets' and does not see in progress tickets from WBRS
  # Scenario: a user selects the 'New Internal Tickets' and does not see tickets from WBRS or from Talos
  # Scenario: a user selects the 'New Internal Tickets' and does not see closed internal tickets
  # Scenario: a user selects the 'New Internal Tickets' and does not see in progress internal tickets

  
  @javascript
  Scenario: a user selects the 'Completed Tickets' filter and only sees tickets with status COMPLETED
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type |  status     | user_id |
      |  1 | abc.com        | abc.com         | URI/DOMAIN |  ASSIGNED   |    1    |
      |  2 | whatever.com   | whatever.com    | URI/DOMAIN |  PENDING    |    1    |
      |  3 | purl.com       | purl.com        | URI/DOMAIN |  NEW        |         |
      |  4 | gurl.com       | gurl.com        | URI/DOMAIN |  COMPLETED  |    1    |
      |  5 | twirl.com      | twirl.com       | URI/DOMAIN |  NEW        |         |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I should see "abc.com"
    And I should see "whatever.com"
    And I should see "purl.com"
    And I should see "gurl.com"
    And I should see "twirl.com"
    And I click "#filter-complaints"
    And I wait for "2" seconds
    And I click "Completed Tickets"
    Then I wait for "6" seconds
    Then I should not see "abc.com"
    And I should not see "whatever.com"
    And I should not see "purl.com"
    And I should see "gurl.com"
    And I should not see "twirl.com"

  @javascript
  Scenario: a user selects the 'Waiting for Review' filter and only sees tickets with status PENDING
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type |  status     | user_id |
      |  1 | abc.com        | abc.com         | URI/DOMAIN |  ASSIGNED   |    1    |
      |  2 | whatever.com   | whatever.com    | URI/DOMAIN |  PENDING    |    1    |
      |  3 | purl.com       | purl.com        | URI/DOMAIN |  PENDING    |    2    |
      |  4 | gurl.com       | gurl.com        | URI/DOMAIN |  COMPLETED  |    1    |
      |  5 | twirl.com      | twirl.com       | URI/DOMAIN |  NEW        |         |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I should see "abc.com"
    And I should see "whatever.com"
    And I should see "purl.com"
    And I should see "gurl.com"
    And I should see "twirl.com"
    And I click "#filter-complaints"
    And I wait for "2" seconds
    And I click "Waiting for Review"
    Then I wait for "6" seconds
    Then I should not see "abc.com"
    And I should see "whatever.com"
    And I should see "purl.com"
    And I should not see "gurl.com"
    And I should not see "twirl.com"






#
#  @javascript
#  Scenario: a user selects the 'Active' filter
#    Given a user with role "webcat user" exists and is logged in
#    And a new complaint entry with trait "pending_entry" exists
#    And a complaint entry preload exists
#    And I goto "/escalations/webcat/complaints?f=ACTIVE"
#    Then I wait for "3" seconds
#    Then I should see "PENDING"
#
#

#
#  @javascript
#  Scenario: a user selects the 'All' filter
#    Given a user with role "webcat user" exists and is logged in
#    And a new complaint entry with trait "assigned_entry" exists
#    And a complaint entry preload exists
#    And I goto "/escalations/webcat/complaints?f=ALL"
#    Then I wait for "3" seconds
#    Then I should see "ASSIGNED"
