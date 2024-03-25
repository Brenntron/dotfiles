Feature: Webcat index top banner

  # webcat > complaints index > new banner w/ metrics
  @javascript
  Scenario: a user sees there is new/assigned Talos/WBNP/internal complaints in webcat index top banner
    Given a user with role "webcat user" exists and is logged in
    And the following complaints exist:
      | channel       | id |
      | talosintel    | 1  |
      | talosintel    | 2  |
      | talosintel    | 3  |
      | talosintel    | 4  |
      | wbnp          | 5  |
      | wbnp          | 6  |
      | wbnp          | 7  |
      | internal      | 8  |
      | internal      | 9  |
    And the following complaint entries exist:
      | uri            | domain          | entry_type | complaint_id | status     |
      | abc.com        | abc.com         | URI/DOMAIN |  1           | NEW        |
      | whatever.com   | whatever.com    | URI/DOMAIN |  2           | NEW        |
      | url.com        | url.com         | URI/DOMAIN |  3           | ASSIGNED   |
      | test.com       | test.com        | URI/DOMAIN |  4           | ASSIGNED   |
      | something.com  | something.com   | URI/DOMAIN |  5           | NEW        |
      | yadayada.com   | yadayada.com    | URI/DOMAIN |  6           | NEW        |
      | nothing.com    | nothing.com     | URI/DOMAIN |  7           | ASSIGNED   |
      | something.com  | something.com   | URI/DOMAIN |  8           | NEW        |
      | blahblah.com   | blahblah.com    | URI/DOMAIN |  9           | ASSIGNED   |
    And I goto "/escalations/webcat/complaints"
    And I wait for "1" seconds
    Then I should see content "2" within "#ti-new-count"
    Then I should see content "2" within "#ti-assigned-count"
    Then I should see content "2" within "#wbnp-new-count"
    Then I should see content "1" within "#wbnp-assigned-count"
    Then I should see content "1" within "#int-new-count"
    Then I should see content "1" within "#int-assigned-count"

# webcat > complaints index > take a ticket, test assigned metric updates
  @javascript
  Scenario: a user sees a new complaint metric after making a New on webcat index, then takes ticket to see its assigned
    Given a user with role "webcat user" exists and is logged in
    And bugzilla rest api always saves
    And I goto "/escalations/webcat/complaints"
    And I wait for "5" seconds
    And I click "#new-complaint"
    And I fill in "ips_urls" with "example.com"
    And I fill in element "#platforms" with "Talosintelligence"
    And I click "#submit-new-complaint"
    And I wait for "5" seconds
    And I click ".close"
    And I wait for "3" seconds
    And I click ".cat-index-main-row"
    And I click ".take-ticket-toolbar-button"
    And I wait for "3" seconds
    Then I should see content "1" within "#int-assigned-count"

  #TODO
  # more scenarios for the banner