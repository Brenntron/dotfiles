Feature: Webrep, the BFRP
  In order to research ad-hoc dispute entries,
  I will provide an interface to search these
  by domain.

  @javascript
  Scenario: Duplicate entries are consolidated into a single row in this view
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
      |id|
      |1 |
      |2 |
      |3 |
    And the following dispute_entries exist:
      |dispute_id           |uri                 |entry_type |
      |1                    |mytestingdomain.com |URI/DOMAIN |
      |2                    |mytestingdomain.com |URI/DOMAIN |
      |3                    |mytestingdomain.com |URI/DOMAIN |
    When I goto "escalations/webrep/research?utf8=1&search%5Buri%5D=mytestingdomain.com&search%5Bscope%5D=strict&commit=Submit"
    Then I wait for "30" seconds
    Then I should see "3 ticket(s)"

  @javascript
  Scenario: Duplicate resolution also works with IP addresses
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
      |id|
      |1 |
      |2 |
      |3 |
    And the following dispute_entries exist:
      |dispute_id           |uri                 |entry_type |
      |1                    |100.100.200.1       |IP         |
      |2                    |100.100.200.1       |IP         |
      |3                    |100.100.200.1       |IP         |
    When I goto "escalations/webrep/research?utf8=1&search%5Buri%5D=100.100.200.1&search%5Bscope%5D=strict&commit=Submit"
    Then I wait for "30" seconds
    Then I should see "3 ticket(s)"

  @javascript
  Scenario: a user wants to verify threat categories appear on page load on BFRP
    Given a user with role "webrep user" exists and is logged in
    When I goto "escalations/webrep/research"
    Then I fill in "search_uri" with "g-oogl-e.com"
    And I click "#submit-button"
    And I wait for "5" seconds
    Then I should see "Malware Sites"
    Then I should see "Exploits"
