Feature: Webcat Categorize URLs dropdown

  @javascript
  Scenario: a user looks up a complaint's entry history without entering a URL
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I click "#history-1"
    Then I should see content "No data available for blank URL." within "#cat-url-1"

  @javascript
  Scenario: a user looks up a complaint's entry history with a valid URL
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I fill in "url_1" with "cisco.com"
    And I click "#history-1"
    And I wait for "5" seconds
    Then I should see "History Information"
    And I should see "DOMAIN HISTORY"
    And I should see "Tue, 12 May 2015 17:39:53 GMT"


  @javascript
  Scenario: a user looks up a complaint's entry history with an invalid URL
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I fill in "url_1" with "fmasoifkis122.com"
    And I click "#history-1"
    And I wait for "5" seconds
    Then I should see "No history associated with this url."


  @javascript
  Scenario: a user looks up a complaint's entry history with an invalid URL in the third position (make sure that the notification appears in the right spot)
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    When I click "#categorize-urls"
    And I fill in "url_3" with "fmasoifkis7788.com"
    And I click "#history-3"
    And I wait for "5" seconds
    Then I should see content "No history associated with this url." within "#cat-url-3"

  @javascript
  Scenario: a users tries to categorize a URL
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I fill in "url_1" with "mary.com"
    And I fill in selectized with "Adult"
    And I click ".primary"
    And I wait for "10" seconds
    Then I should see "URLS CATEGORIZED SUCCESSFULLY"
    And I should see "entries have been submitted directly to WBRS."

  @javascript
  Scenario: a users tries to categorize without selecting a category
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I fill in "url_1" with "cisco.com"
    And I click ".primary"
    Then I should see "UNABLE TO CATEGORIZE"
    And I should see "Please confirm that a URL and at least one category for each desired entry exists."

  @javascript
  Scenario: a users tries to categorize without an URL
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I fill in selectized with "Adult"
    And I click ".primary"
    Then I should see "UNABLE TO CATEGORIZE"
    And I should see "Please confirm that a URL and at least one category for each desired entry exists."

  @javascript
  Scenario: a users tries to categorize a URL with an empty form
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I click ".primary"
    Then I should see "UNABLE TO CATEGORIZE"
    And I should see "Please confirm that a URL and at least one category for each desired entry exists."

  @javascript
  Scenario: a users tries submits a multiple url categorization
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I click "#cat-urls-same"
    And I fill in "categorize_urls" with "joseph.com" and "mary.com" separated by blank lines
    And I fill in selectized with "Adult"
    And I click "#cat-urls-same"
    And I click ".primary"
    And I wait for "15" seconds
    Then I should see "SUCCESS"
    And I should see "URLs/IPs successfully categorized."

  @javascript
  Scenario: a users tries submits a multiple url categorization without a URL
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I click "#cat-urls-same"
    And I fill in selectized with "Adult"
    And I click "#cat-urls-same"
    And I click ".primary"
    Then I should see "ERROR"
    Then I should see "Please check that a URL/IP has been inputted and that at least one category was selected."

  @javascript
  Scenario: a users tries submits a multiple url categorization without a category
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I click "#cat-urls-same"
    And I fill in "categorize_urls" with "cisco.com"
    And I click ".primary"
    Then I should see "ERROR"
    Then I should see "Please check that a URL/IP has been inputted and that at least one category was selected."


  @javascript
  Scenario: a users tries to lookup categories for a URL
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I fill in "url_1" with "chabad.org"
    And I click ".current-categories-button"
    Then I wait for "5" seconds

  @javascript
  Scenario: a users tries to lookup categories for a URL that has a categorized subdomain and a uncategorized domain
    Given a user with role "webcat user" exists and is logged in
    And the following complaint entries exist:
      | id  | uri                                       | domain                                     | entry_type | status | url_primary_category | category               |
      | 111 | trial.superduperreallyfakeamazing.com     | trial.superduperreallyfakeamazing.com      | URI/DOMAIN | NEW    | Health and Nutrition | Health and Nutrition   |
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I fill in "url_1" with "trial.superduperreallyfakeamazing.com"
    And I click ".current-categories-button"
    And I wait for "5" seconds
    And take a screenshot
    And pending
#    Then I should see content "Religion" within ".item"
#    And I fill in "url_1" with "superduperreallyfakeamazing.com"
#    And I click ".current-categories-button"
#    And I wait for "5" seconds
#    Then I should not see div element with class ".item"

  @javascript
  Scenario: a users tries to drop current categories on a URL
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I fill in "url_1" with "washingtonpost.com"
    And I click ".delete-categories-button"
    And I wait for "10" seconds
    Then I should see "Categories successfully dropped."

  @javascript
  Scenario: user should get credit for direct categorizations for non-important urls
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I fill in "url_1" with "example123.com"
    And I fill in selectized with "Advertisements"
    And I click ".primary"
    And I wait for "10" seconds
    Then I should see "URLS CATEGORIZED SUCCESSFULLY"
    And I should see "No pending complaint entries have been created All other entries have been submitted directly to WBRS."
    Then I goto a "resolution" report surrounding the current year
    And I should see my username

  @javascript
  Scenario: user should see the link to refresh the page after categorization
    Given a user with role "webcat user" exists and is logged in
    When I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#categorize-urls"
    And I fill in "url_1" with "example123.com"
    And I fill in selectized with "Advertisements"
    And I click ".primary"
    And I wait for "10" seconds
    Then I should see "URLS CATEGORIZED SUCCESSFULLY"
    And I should see "Refresh the page to see the result"
    Then I goto a "resolution" report surrounding the current year
    And I should see my username