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


  @javascript
  Scenario: a user selects the 'New Talos Tickets' and does not see internal tickets or tickets from WBRS
    Given a user with role "webcat user" exists and is logged in
    Given the following complaints exist:
      | id | customer_id |  channel       |
      | 1  | 1           |   talosintel   |
      | 2  | 2           |   wbnp         |
      | 3  | 3           |   internal     |
    And the following complaint entries exist:
      | id | uri            | domain            | entry_type |  status     | user_id | complaint_id |
      |  1 | abc.com        | abc.com           | URI/DOMAIN |  NEW        |    1    | 1            |
      |  2 | whatever.com   | whatever.com      | URI/DOMAIN |  NEW        |    1    | 1            |
      |  3 | purl.com       | purl.com          | URI/DOMAIN |  NEW        |         | 2            |
      |  4 | gurl.com       | gurl.com          | URI/DOMAIN |  NEW        |    1    | 2            |
      |  5 | twirl.com      | twirl.com         | URI/DOMAIN |  NEW        |         | 3            |
      |  6 | unfurl.com     | unfurl.com        | URI/DOMAIN |  NEW        |         | 3            |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I should see "abc.com"
    And I should see "whatever.com"
    And I should see "purl.com"
    And I should see "gurl.com"
    And I should see "twirl.com"
    And I should see "unfurl.com"
    And I click "#filter-complaints"
    And I wait for "2" seconds
    Then I click "New Talos Tickets"
    Then I wait for "6" seconds
    And I should see "abc.com"
    And I should see "whatever.com"
    And I should not see "purl.com"
    And I should not see "gurl.com"
    And I should not see "twirl.com"
    And I should not see "unfurl.com"

  @javascript
  Scenario: a user selects the 'New Talos Tickets' and does not see closed tickets from Talos
    Given a user with role "webcat user" exists and is logged in
    Given the following complaints exist:
      | id | customer_id |  channel       |
      | 1  | 1           |   talosintel   |
    And the following complaint entries exist:
      | id | uri            | domain            | entry_type |  status     | user_id | complaint_id |
      |  1 | abc.com        | abc.com           | URI/DOMAIN |  RESOLVED   |    1    |     1        |
      |  2 | whatever.com   | whatever.com      | URI/DOMAIN |  PENDING    |    1    |     1        |
      |  3 | purl.com       | purl.com          | URI/DOMAIN |  NEW        |         |     1        |
      |  4 | gurl.com       | gurl.com          | URI/DOMAIN |  COMPLETED  |    1    |     1        |
      |  5 | twirl.com      | twirl.com         | URI/DOMAIN |  NEW        |         |     1        |
      |  6 | unfurl.com     | unfurl.com        | URI/DOMAIN |  COMPLETED  |         |     1        |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I should see "abc.com"
    And I should see "whatever.com"
    And I should see "purl.com"
    And I should see "gurl.com"
    And I should see "twirl.com"
    And I should see "unfurl.com"
    And I click "#filter-complaints"
    And I wait for "2" seconds
    Then I click "New Talos Tickets"
    Then I wait for "6" seconds
    And I should not see "abc.com"
    And I should not see "whatever.com"
    And I should see "purl.com"
    And I should not see "gurl.com"
    And I should see "twirl.com"
    And I should not see "unfurl.com"

  @javascript
  Scenario: a user selects the 'New Talos Tickets' and does not see in progress tickets from Talos
    Given a user with role "webcat user" exists and is logged in
    Given the following complaints exist:
      | id | customer_id |  channel       |
      | 1  | 1           |   talosintel   |
    And the following complaint entries exist:
      | id | uri            | domain            | entry_type |  status     | user_id | complaint_id |
      |  1 | abc.com        | abc.com           | URI/DOMAIN |  RESOLVED   |    1    |     1        |
      |  2 | whatever.com   | whatever.com      | URI/DOMAIN |  ACTIVE     |    1    |     1        |
      |  3 | purl.com       | purl.com          | URI/DOMAIN |  NEW        |         |     1        |
      |  4 | gurl.com       | gurl.com          | URI/DOMAIN |  COMPLETED  |    1    |     1        |
      |  5 | twirl.com      | twirl.com         | URI/DOMAIN |  NEW        |         |     1        |
      |  6 | unfurl.com     | unfurl.com        | URI/DOMAIN |  ACTIVE     |         |     1        |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I should see "abc.com"
    And I should see "whatever.com"
    And I should see "purl.com"
    And I should see "gurl.com"
    And I should see "twirl.com"
    And I should see "unfurl.com"
    And I click "#filter-complaints"
    And I wait for "2" seconds
    Then I click "New Talos Tickets"
    Then I wait for "6" seconds
    And I should not see "abc.com"
    And I should not see "whatever.com"
    And I should see "purl.com"
    And I should not see "gurl.com"
    And I should see "twirl.com"
    And I should not see "unfurl.com"

  @javascript
  Scenario: Scenario: a user selects the 'New WBNP Tickets' and does not see internal tickets or tickets from Talos
    Given a user with role "webcat user" exists and is logged in
    Given the following complaints exist:
      | id | customer_id |  channel       |
      | 1  | 1           |   talosintel   |
      | 2  | 2           |   wbnp         |
      | 3  | 3           |   internal     |
    And the following complaint entries exist:
      | id | uri            | domain            | entry_type |  status     | user_id | complaint_id |
      |  1 | abc.com        | abc.com           | URI/DOMAIN |  NEW        |    1    | 1            |
      |  2 | whatever.com   | whatever.com      | URI/DOMAIN |  NEW        |    1    | 1            |
      |  3 | purl.com       | purl.com          | URI/DOMAIN |  NEW        |         | 2            |
      |  4 | gurl.com       | gurl.com          | URI/DOMAIN |  NEW        |    1    | 2            |
      |  5 | twirl.com      | twirl.com         | URI/DOMAIN |  NEW        |         | 3            |
      |  6 | unfurl.com     | unfurl.com        | URI/DOMAIN |  NEW        |         | 3            |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I should see "abc.com"
    And I should see "whatever.com"
    And I should see "purl.com"
    And I should see "gurl.com"
    And I should see "twirl.com"
    And I should see "unfurl.com"
    And I click "#filter-complaints"
    And I wait for "2" seconds
    Then I click "New WBNP Tickets"
    Then I wait for "6" seconds
    And I should not see "abc.com"
    And I should not see "whatever.com"
    And I should see "purl.com"
    And I should see "gurl.com"
    And I should not see "twirl.com"
    And I should not see "unfurl.com"

  @javascript
  Scenario: Scenario: a user selects the 'New WBNP Tickets' and does not see closed tickets from WBNP
    Given a user with role "webcat user" exists and is logged in
    Given the following complaints exist:
      | id | customer_id |  channel       |
      | 1  | 1           |   talosintel   |
      | 2  | 2           |   wbnp         |
      | 3  | 3           |   internal     |
    And the following complaint entries exist:
      | id | uri            | domain            | entry_type |  status     | user_id | complaint_id |
      |  1 | abc.com        | abc.com           | URI/DOMAIN |  RESOLVED   |    1    | 2            |
      |  2 | whatever.com   | whatever.com      | URI/DOMAIN |  ACTIVE     |    1    | 2            |
      |  3 | purl.com       | purl.com          | URI/DOMAIN |  COMPLETED  |         | 2            |
      |  4 | gurl.com       | gurl.com          | URI/DOMAIN |  NEW        |    1    | 2            |
      |  5 | twirl.com      | twirl.com         | URI/DOMAIN |  NEW        |         | 2            |
      |  6 | unfurl.com     | unfurl.com        | URI/DOMAIN |  NEW        |         | 2            |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I should see "abc.com"
    And I should see "whatever.com"
    And I should see "purl.com"
    And I should see "gurl.com"
    And I should see "twirl.com"
    And I should see "unfurl.com"
    And I click "#filter-complaints"
    And I wait for "2" seconds
    Then I click "New WBNP Tickets"
    Then I wait for "6" seconds
    And I should not see "abc.com"
    And I should not see "whatever.com"
    And I should not see "purl.com"
    And I should see "gurl.com"
    And I should see "twirl.com"
    And I should see "unfurl.com"

  @javascript
  Scenario: a user selects the 'New WBNP Tickets' and does not see in progress tickets from WBNP
    Given a user with role "webcat user" exists and is logged in
    Given the following complaints exist:
      | id | customer_id |  channel       |
      | 1  | 1           |   talosintel   |
      | 2  | 2           |   wbnp         |
      | 3  | 3           |   internal     |
    And the following complaint entries exist:
      | id | uri            | domain            | entry_type |  status     | user_id | complaint_id |
      |  1 | abc.com        | abc.com           | URI/DOMAIN |  ACTIVE     |    1    | 2            |
      |  2 | whatever.com   | whatever.com      | URI/DOMAIN |  ACTIVE     |    1    | 2            |
      |  3 | purl.com       | purl.com          | URI/DOMAIN |  ACTIVE     |         | 2            |
      |  4 | gurl.com       | gurl.com          | URI/DOMAIN |  NEW        |    1    | 2            |
      |  5 | twirl.com      | twirl.com         | URI/DOMAIN |  NEW        |         | 2            |
      |  6 | unfurl.com     | unfurl.com        | URI/DOMAIN |  NEW        |         | 2            |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I should see "abc.com"
    And I should see "whatever.com"
    And I should see "purl.com"
    And I should see "gurl.com"
    And I should see "twirl.com"
    And I should see "unfurl.com"
    And I click "#filter-complaints"
    And I wait for "2" seconds
    Then I click "New WBNP Tickets"
    Then I wait for "6" seconds
    And I should not see "abc.com"
    And I should not see "whatever.com"
    And I should not see "purl.com"
    And I should see "gurl.com"
    And I should see "twirl.com"
    And I should see "unfurl.com"

  @javascript
  Scenario: a user selects the 'New Internal Tickets' and does not see tickets from WBRS or from Talos
    Given a user with role "webcat user" exists and is logged in
    Given the following complaints exist:
      | id | customer_id |  channel       |
      | 1  | 1           |   talosintel   |
      | 2  | 2           |   wbnp         |
      | 3  | 3           |   internal     |
    And the following complaint entries exist:
      | id | uri            | domain            | entry_type |  status     | user_id | complaint_id |
      |  1 | abc.com        | abc.com           | URI/DOMAIN |  RESOLVED   |    1    | 1            |
      |  2 | whatever.com   | whatever.com      | URI/DOMAIN |  ACTIVE     |    1    | 1            |
      |  3 | purl.com       | purl.com          | URI/DOMAIN |  COMPLETED  |         | 2            |
      |  4 | gurl.com       | gurl.com          | URI/DOMAIN |  NEW        |    1    | 2            |
      |  5 | twirl.com      | twirl.com         | URI/DOMAIN |  NEW        |         | 3            |
      |  6 | unfurl.com     | unfurl.com        | URI/DOMAIN |  NEW        |         | 3            |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I should see "abc.com"
    And I should see "whatever.com"
    And I should see "purl.com"
    And I should see "gurl.com"
    And I should see "twirl.com"
    And I should see "unfurl.com"
    And I click "#filter-complaints"
    And I wait for "2" seconds
    Then I click "New Internal Tickets"
    Then I wait for "6" seconds
    And I should not see "abc.com"
    And I should not see "whatever.com"
    And I should not see "purl.com"
    And I should not see "gurl.com"
    And I should see "twirl.com"
    And I should see "unfurl.com"

  # Scenario: a user selects the 'New Internal Tickets' and does not see closed internal tickets
  @javascript
  Scenario: a user selects the 'New Internal Tickets' and does not see closed internal tickets
    Given a user with role "webcat user" exists and is logged in
    Given the following complaints exist:
      | id | customer_id |  channel       |
      | 1  | 1           |   talosintel   |
      | 2  | 2           |   wbnp         |
      | 3  | 3           |   internal     |
    And the following complaint entries exist:
      | id | uri            | domain            | entry_type |  status     | user_id | complaint_id |
      |  1 | abc.com        | abc.com           | URI/DOMAIN |  RESOLVED   |    1    | 3            |
      |  2 | whatever.com   | whatever.com      | URI/DOMAIN |  RESOLVED   |    1    | 3            |
      |  3 | purl.com       | purl.com          | URI/DOMAIN |  COMPLETED  |         | 3            |
      |  4 | gurl.com       | gurl.com          | URI/DOMAIN |  NEW        |    1    | 3            |
      |  5 | twirl.com      | twirl.com         | URI/DOMAIN |  NEW        |         | 3            |
      |  6 | unfurl.com     | unfurl.com        | URI/DOMAIN |  NEW        |         | 3            |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I should see "abc.com"
    And I should see "whatever.com"
    And I should see "purl.com"
    And I should see "gurl.com"
    And I should see "twirl.com"
    And I should see "unfurl.com"
    And I click "#filter-complaints"
    And I wait for "2" seconds
    Then I click "New Internal Tickets"
    Then I wait for "6" seconds
    And I should not see "abc.com"
    And I should not see "whatever.com"
    And I should not see "purl.com"
    And I should see "gurl.com"
    And I should see "twirl.com"
    And I should see "unfurl.com"

  @javascript
  Scenario: a user selects the 'New Internal Tickets' and does not see in progress internal tickets
    Given a user with role "webcat user" exists and is logged in
    Given the following complaints exist:
      | id | customer_id |  channel       |
      | 1  | 1           |   talosintel   |
      | 2  | 2           |   wbnp         |
      | 3  | 3           |   internal     |
    And the following complaint entries exist:
      | id | uri            | domain            | entry_type |  status     | user_id | complaint_id |
      |  1 | abc.com        | abc.com           | URI/DOMAIN |  ACTIVE     |    1    | 3            |
      |  2 | whatever.com   | whatever.com      | URI/DOMAIN |  ACTIVE     |    1    | 3            |
      |  3 | purl.com       | purl.com          | URI/DOMAIN |  ACTIVE     |         | 3            |
      |  4 | gurl.com       | gurl.com          | URI/DOMAIN |  NEW        |    1    | 3            |
      |  5 | twirl.com      | twirl.com         | URI/DOMAIN |  NEW        |         | 3            |
      |  6 | unfurl.com     | unfurl.com        | URI/DOMAIN |  NEW        |         | 3            |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I should see "abc.com"
    And I should see "whatever.com"
    And I should see "purl.com"
    And I should see "gurl.com"
    And I should see "twirl.com"
    And I should see "unfurl.com"
    And I click "#filter-complaints"
    And I wait for "2" seconds
    Then I click "New Internal Tickets"
    Then I wait for "6" seconds
    And I should not see "abc.com"
    And I should not see "whatever.com"
    And I should not see "purl.com"
    And I should see "gurl.com"
    And I should see "twirl.com"
    And I should see "unfurl.com"

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

  @javascript
  Scenario: a user selects the 'Active Tickets' filter and does not see tickets with status 'NEW' or 'COMPLETED'
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
    And I click "Active Tickets"
    Then I wait for "6" seconds
    Then I should see "abc.com"
    And I should see "whatever.com"
    And I should see "purl.com"
    And I should not see "gurl.com"
    And I should not see "twirl.com"

  @javascript
  Scenario: a user selects the 'All Tickets' filter and can see tickets of every status
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type |  status     | user_id |
      |  1 | abc.com        | abc.com         | URI/DOMAIN |  ASSIGNED   |    1    |
      |  2 | whatever.com   | whatever.com    | URI/DOMAIN |  PENDING    |    1    |
      |  3 | purl.com       | purl.com        | URI/DOMAIN |  PENDING    |    2    |
      |  4 | gurl.com       | gurl.com        | URI/DOMAIN |  COMPLETED  |    1    |
      |  5 | twirl.com      | twirl.com       | URI/DOMAIN |  NEW        |         |
    And I goto "/escalations/webcat/complaints?f=NEW"
    And I should not see "abc.com"
    And I should not see "whatever.com"
    And I should not see "purl.com"
    And I should not see "gurl.com"
    And I should see "twirl.com"
    And I click "#filter-complaints"
    And I wait for "2" seconds
    And I click "All Tickets"
    Then I wait for "6" seconds
    And I should see "abc.com"
    And I should see "whatever.com"
    And I should see "purl.com"
    And I should see "gurl.com"
    And I should see "twirl.com"


  @javascript
  Scenario: left nav links should apply filter if the filter was set before
    Given a user with role "webcat user" exists and is logged in
    And a new complaint entry with trait "assigned_entry" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=MY%20COMPLAINTS"
    Then I wait for "3" seconds
    Then I should see "ASSIGNED"
    When I click "#nav-trigger-label"
    And I click "Escalations"
    And I click "#cat-icon-link"
    Then I wait for "3" seconds
    Then I should see "ASSIGNED"
    When I click "#nav-trigger-label"
    And I click "Escalations"
    And I click "#cat-link"
    Then I wait for "3" seconds
    Then I should see "ASSIGNED"

  @javascript
  Scenario: top nav links should apply filter if the filter was set before
    Given a user with role "webcat user" exists and is logged in
    And a new complaint entry with trait "assigned_entry" exists
    And a complaint entry preload exists
    And I goto "/escalations/webcat/complaints?f=MY%20COMPLAINTS"
    Then I wait for "3" seconds
    Then I should see "ASSIGNED"
    When I click "#complaints"
    Then I wait for "3" seconds
    Then I should see "ASSIGNED"

  @javascript
  Scenario: The default table filters should be loaded when no other filter changes are saved
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type |  status     | user_id |
      |  1 | abc.com        | abc.com         | URI/DOMAIN |  ASSIGNED   |    1    |
    #New Talos Tickets
    And I goto "/escalations/webcat/complaints?f=NEW%20TALOS"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tags-col-cb" checkbox unchecked
    Then I should see the "#view-description-col-cb" checkbox checked
    Then I should see the "#view-sugg-col-cb" checkbox checked
    #New WBNP Tickets
    And I goto "/escalations/webcat/complaints?f=NEW%20WBNP"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tags-col-cb" checkbox unchecked
    Then I should see the "#view-description-col-cb" checkbox unchecked
    Then I should see the "#view-sugg-col-cb" checkbox unchecked
    #New Jira Tickets
    And I goto "/escalations/webcat/complaints?f=NEW%20JIRA"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tags-col-cb" checkbox checked
    Then I should see the "#view-description-col-cb" checkbox checked
    Then I should see the "#view-sugg-col-cb" checkbox unchecked
    #New Internal Tickets
    And I goto "/escalations/webcat/complaints?f=NEW%20INTERNAL"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tags-col-cb" checkbox checked
    Then I should see the "#view-description-col-cb" checkbox unchecked
    Then I should see the "#view-sugg-col-cb" checkbox unchecked
    #All Other Ticket Filters
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tags-col-cb" checkbox checked
    Then I should see the "#view-description-col-cb" checkbox checked
    Then I should see the "#view-sugg-col-cb" checkbox checked

  @javascript
  Scenario: A webcat user can save New Talos Tickets column data without it effecting the other filtered tables
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type |  status     | user_id |
      |  1 | abc.com        | abc.com         | URI/DOMAIN |  ASSIGNED   |    1    |
    #New Talos Tickets
    And I goto "/escalations/webcat/complaints?f=NEW%20TALOS"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox unchecked
    Then I click "#view-tools-col-cb"
    Then I should see the "#view-tools-col-cb" checkbox checked
    #Confirm all filters below do not save the first check (Tools is not checked by default anywhere)
    #New WBNP Tickets
    And I goto "/escalations/webcat/complaints?f=NEW%20WBNP"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox unchecked
    #New Jira Tickets
    And I goto "/escalations/webcat/complaints?f=NEW%20JIRA"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox unchecked
    #New Internal Tickets
    And I goto "/escalations/webcat/complaints?f=NEW%20INTERNAL"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox unchecked
    #All Other Ticket Filters
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox unchecked
    #Confirm first check is still saved
    And I goto "/escalations/webcat/complaints?f=NEW%20TALOS"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox checked

  @javascript
  Scenario: A webcat user can save New WBNP Tickets column data without it effecting the other filtered tables
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type |  status     | user_id |
      |  1 | abc.com        | abc.com         | URI/DOMAIN |  ASSIGNED   |    1    |
    #New WBNP Tickets
    And I goto "/escalations/webcat/complaints?f=NEW%20WBNP"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox unchecked
    Then I click "#view-tools-col-cb"
    Then I should see the "#view-tools-col-cb" checkbox checked
    #Confirm all filters below do not save the first check (Tools is not checked by default anywhere)
    #New Talos Tickets
    And I goto "/escalations/webcat/complaints?f=NEW%20TALOS"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox unchecked
    #New Jira Tickets
    And I goto "/escalations/webcat/complaints?f=NEW%20JIRA"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox unchecked
    #New Internal Tickets
    And I goto "/escalations/webcat/complaints?f=NEW%20INTERNAL"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox unchecked
    #All Other Ticket Filters
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox unchecked
    #Confirm first check is still saved
    And I goto "/escalations/webcat/complaints?f=NEW%20WBNP"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox checked

  @javascript
  Scenario: A webcat user can save New Jira Tickets column data without it effecting the other filtered tables
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type |  status     | user_id |
      |  1 | abc.com        | abc.com         | URI/DOMAIN |  ASSIGNED   |    1    |
    #New Jira Tickets
    And I goto "/escalations/webcat/complaints?f=NEW%20JIRA"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox unchecked
    Then I click "#view-tools-col-cb"
    Then I should see the "#view-tools-col-cb" checkbox checked
    #Confirm all filters below do not save the first check (Tools is not checked by default anywhere)
    #New Talos Tickets
    And I goto "/escalations/webcat/complaints?f=NEW%20TALOS"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox unchecked
    #New WBNP Tickets
    And I goto "/escalations/webcat/complaints?f=NEW%20WBNP"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox unchecked
    #New Internal Tickets
    And I goto "/escalations/webcat/complaints?f=NEW%20INTERNAL"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox unchecked
    #All Other Ticket Filters
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox unchecked
    #Confirm first check is still saved
    And I goto "/escalations/webcat/complaints?f=NEW%20JIRA"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox checked

  @javascript
  Scenario: A webcat user can save New Internal Tickets column data without it effecting the other filtered tables
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type |  status     | user_id |
      |  1 | abc.com        | abc.com         | URI/DOMAIN |  ASSIGNED   |    1    |
    #New Internal Tickets
    And I goto "/escalations/webcat/complaints?f=NEW%20INTERNAL"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox unchecked
    Then I click "#view-tools-col-cb"
    Then I should see the "#view-tools-col-cb" checkbox checked
    #Confirm all filters below do not save the first check (Tools is not checked by default anywhere)
    #New Talos Tickets
    And I goto "/escalations/webcat/complaints?f=NEW%20TALOS"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox unchecked
    #New WBNP Tickets
    And I goto "/escalations/webcat/complaints?f=NEW%20WBNP"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox unchecked
    #New Jira Tickets
    And I goto "/escalations/webcat/complaints?f=NEW%20JIRA"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox unchecked
    #All Other Ticket Filters
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox unchecked
    #Confirm first check is still saved
    And I goto "/escalations/webcat/complaints?f=NEW%20INTERNAL"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox checked

  @javascript
  Scenario: A webcat user can save the default (no specific filter) column data without it effecting the other filtered tables
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id | uri            | domain          | entry_type |  status     | user_id |
      |  1 | abc.com        | abc.com         | URI/DOMAIN |  ASSIGNED   |    1    |
    #Default Tickets
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox unchecked
    Then I click "#view-tools-col-cb"
    Then I should see the "#view-tools-col-cb" checkbox checked
    #Confirm all filters below do not save the first check (Tools is not checked by default anywhere)
    #New Talos Tickets
    And I goto "/escalations/webcat/complaints?f=NEW%20TALOS"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox unchecked
    #New WBNP Tickets
    And I goto "/escalations/webcat/complaints?f=NEW%20WBNP"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox unchecked
    #New Jira Tickets
    And I goto "/escalations/webcat/complaints?f=NEW%20JIRA"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox unchecked
    #New Internal Tickets
    And I goto "/escalations/webcat/complaints?f=NEW%20INTERNAL"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox unchecked
    #Confirm first check is still saved
    And I goto "/escalations/webcat/complaints?f=MY%20OPEN%20COMPLAINTS"
    And I click "#webcat-index-table-show-columns-button"
    Then I should see the "#view-tools-col-cb" checkbox checked

#TODO - add tests for the favorite filter
  # - a user sets a favorite filter and when they go to the index it loads that filter
  # - a user has a set favorite filter, looks at a different filtered result set and uses the clear button to return to their chosen default
  # - a user has a set favorite filter, performs a search and uses the clear button to return to their chosen default
  # - a user has a set favorite filter, performs an advanced search and uses the clear button to return to their chosen default
  # - a user changes their favorite filter and on refresh the filter dropdown shows the newly selected filter as starred

