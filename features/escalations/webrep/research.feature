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
  Scenario: a user wants to verify threat categories appear inside inline adjust wl/bl dropdown
    Given a user with role "webrep user" exists and is logged in
    When I goto "escalations/webrep/research"
    Then I fill in "search_uri" with "g-oogl-e.com"
    And I click "#submit-button"
    And I wait for "5" seconds
    And I click ".bfrp-inline-wlbl-button"
    And I wait for "5" seconds
    Then I should see "Malware Sites"
    And I should see "Bogon"

  @javascript
  Scenario: a user wants to verify threat categories appear on page load on BFRP
    Given a user with role "webrep user" exists and is logged in
    When I goto "escalations/webrep/research"
    Then I fill in "search_uri" with "g-oogl-e.com"
    And I click "#submit-button"
    And I wait for "5" seconds
    Then I should see "Malware Sites"

  @javascript
  Scenario: a user wants to add a WL to an entry through the inline adjust wl/bl dropdown
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
      |id|
      |1 |
    And the following dispute_entries exist:
      |dispute_id           |uri                 |entry_type |
      |1                    |mytestingdomain.com |URI/DOMAIN |
    When I goto "escalations/webrep/disputes/1"
    And I click "#research-tab-link"
    And I click ".bfrp-inline-wlbl-button"
    And I wait for "2" seconds
    And I click "#wl-weak-slider"
    And I click ".dropdown-submit-button"
    And I wait for "5" seconds
    And I click "#sync-data-button"
    And I wait for "15" seconds
    Then I should see "WL-weak"

  @javascript
  Scenario: a user wants to add a BL to an entry through the INLINE adjust wl/bl dropdown
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
      |id|
      |2 |
    And the following dispute_entries exist:
      |dispute_id    |uri                      |entry_type |
      |2             |myothertestingdomain.com |URI/DOMAIN |
    When I goto "escalations/webrep/disputes/2"
    And I click "#research-tab-link"
    And I click ".bfrp-inline-wlbl-button"
    And I click "#bl-heavy-slider"
    And I wait for "2" seconds
    And I click ".threat-cat-cell:first-of-type"
    And I click ".dropdown-submit-button"
    And I wait for "5" seconds
    And I click "#sync-data-button"
    And I wait for "15" seconds
    Then I should see "BL-heavy"

  @javascript
  Scenario: a user wants to add a WL to an entry through the BULK adjust wl/bl dropdown menu
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
      |id|
      |1 |
    And the following dispute_entries exist:
      |dispute_id    |uri                 |entry_type |
      |1             |mytestingdomain.com |URI/DOMAIN |
    When I goto "escalations/webrep/disputes"
    And I click ".expand-row-button-inline"
    And I click ".dispute-entry-checkbox"
    And I click "#index-adjust-wlbl"
    And I wait for "5" seconds
    And I click ".wl-med-checkbox"
    And I click ".dropdown-submit-button"
    And I wait for "2" seconds
    And I click ".close"
    And I wait for "5" seconds
    And I click "#index-adjust-wlbl"
    And I wait for "5" seconds
    Then I should see "WL-med"

  @javascript
  Scenario: a user wants to add a BL to an entry through the BULK adjust wl/bl dropdown menu
    Given a user with role "webrep user" exists and is logged in
    And the following disputes exist:
      |id|
      |2 |
    And the following dispute_entries exist:
      |dispute_id    |uri                        |entry_type |
      |2             |myamazingtestingdomain.com |URI/DOMAIN |
    When I goto "escalations/webrep/disputes"
    And I click ".expand-row-button-inline"
    And I click ".dispute-entry-checkbox"
    And I click "#index-adjust-wlbl"
    And I wait for "5" seconds
    And I click ".bl-med-checkbox"
    And I click ".threat-cat-cell:first-of-type"
    And I click ".dropdown-submit-button"
    And I wait for "2" seconds
    And I click ".close"
    And I wait for "5" seconds
    And I click "#index-adjust-wlbl"
    And I wait for "5" seconds
    Then I should see "BL-med"
