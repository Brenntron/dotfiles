Feature: Webrep, the BFRP
  In order to research ad-hoc dispute entries,
  I will provide an interface to search these
  by domain.

  @javascript @now
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

  @javascript @now
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
  Scenario: A user uses broad search
    Given a user with role "webrep user" exists and is logged in
    And I go to "escalations/webrep/research"
    When I click "#research-search-broad"
    And I fill in "search_uri" with "blizzard.com"
    And I click "#submit-button"
    And I wait for "30" seconds
    Then multiple research entry exists

  @javascript
  Scenario: A user uses strict search
    Given a user with role "webrep user" exists and is logged in
    And I go to "escalations/webrep/research"
    When I click "#research-search-strict"
    And I fill in "search_uri" with "cisco.com"
    And I click "#submit-button"
    And I wait for "15" seconds
    Then one research entry exists
    
  Scenario: a user searches for a url on the research page that has a threat category assigned to it already
    Given a user with role "webrep user" exists and is logged in
    When I goto "escalations/webrep/research"
    And  I choose "research-search-strict"
    And  I type content "1234computer.com" within input with id "search_uri"
    Then I click "Submit"
    And  I wait for "10" seconds
    And  I should see "1 found"
    And  take a screenshot
    And  Element with class "wlbl-tc-research-span" should have content "Malware Sites"


  @javascript
  Scenario: a user searches for a url on the research page and tries to add a result to a WBRS list but doesn't select any entries
    Given a user with role "webrep user" exists and is logged in
    And  clean up wlbl and remove all wlbl entries on "testing.com"
    When I goto "escalations/webrep/research"
    And  I choose "research-search-strict"
    And  I type content "testing.com" within input with id "search_uri"
    Then I click "Submit"
    And  I wait for "20" seconds
    And  I click button "wlbl_entries_button"
    And  I should see "NO ROWS SELECTED"
    And  take a screenshot


  @javascript
  Scenario: a user searches for a url on the research page and adds a result to a WBRS List
    Given a user with role "webrep user" exists and is logged in
    And  clean up wlbl and remove all wlbl entries on "testing.com"
    When I goto "escalations/webrep/research"
    And  I choose "research-search-strict"
    And  I type content "testing.com" within input with id "search_uri"
    Then I click "Submit"
    And  I wait for "60" seconds
    And  take a screenshot
    And  I click ".bfrp-inline-wlbl-6"
    And  I wait for "5" seconds
    And  Element with class "wlbl-entry-wlbl" should not have content "BL-med"
    Then I click "#bl-med-slider"
    And  I should see "Threat Categories"
    And  I click ".wlbl_thrt_cat_id_8"
    And  I click "Submit Changes"
    And  I wait for "10" seconds
    And  I should see "ENTRY HAS BEEN UPDATED"
    And  I should see "Has been added"
    And  I click ".close"
    And  I wait for "2" seconds
    Then I click ".bfrp-inline-wlbl-6"
    And  Element with class "wlbl-entry-wlbl" should have content "BL-med"
    And  clean up wlbl and remove all wlbl entries on "testing.com"


  @javascript
  Scenario: a user searches for a url on the research page and removes a result from a WBRS List
    Given a user with role "webrep user" exists and is logged in
    And  clean up wlbl and remove all wlbl entries on "testing.com"
    When I goto "escalations/webrep/research"
    And  I choose "research-search-strict"
    And  I type content "testing.com" within input with id "search_uri"
    Then I click "Submit"
    And  I wait for "60" seconds
    And  I click ".bfrp-inline-wlbl-6"
    And  I wait for "5" seconds
    Then I click "#bl-med-slider"
    And  I should see "Threat Categories"
    And  I click ".wlbl_thrt_cat_id_8"
    And  I click "Submit Changes"
    And  I wait for "10" seconds
    And  I should see "ENTRY HAS BEEN UPDATED"
    And  I should see "Has been added"
    And  I click ".close"
    And  I wait for "2" seconds
#    Here is where we actually remove
    Then I click ".bfrp-inline-wlbl-6"
    And  Element with class "wlbl-entry-wlbl" should have content "BL-med"
    Then I click "#bl-med-slider"
    And  I click "Submit Changes"
    And  I wait for "10" seconds
    And  I should see "ENTRY HAS BEEN UPDATED"
    And  I should see "Has been removed"
    And  I click ".close"
    And  I wait for "2" seconds
    Then I click ".bfrp-inline-wlbl-6"
    And  Element with class "wlbl-entry-wlbl" should not have content "BL-med"
    And  take a screenshot
    And  clean up wlbl and remove all wlbl entries on "testing.com"



  @javascript
  Scenario: a user searches for a url on the research page and removes a result from a WBRS List and adds it to another
    Given a user with role "webrep user" exists and is logged in
    And  clean up wlbl and remove all wlbl entries on "testing.com"
    When I goto "escalations/webrep/research"
    And  I choose "research-search-strict"
    And  I type content "testing.com" within input with id "search_uri"
    Then I click "Submit"
    And  I wait for "60" seconds
    And  I click ".bfrp-inline-wlbl-6"
    And  I wait for "5" seconds
    Then I click "#bl-med-slider"
    And  I should see "Threat Categories"
    And  I click ".wlbl_thrt_cat_id_8"
    And  I click "Submit Changes"
    And  I wait for "10" seconds
    And  I should see "ENTRY HAS BEEN UPDATED"
    And  I should see "Has been added"
    And  I click ".close"
    And  I wait for "2" seconds
#    Here is where we actually remove / add new
    Then I click ".bfrp-inline-wlbl-6"
    And  Element with class "wlbl-entry-wlbl" should have content "BL-med"
    Then I click "#bl-med-slider"
    Then I click "#wl-weak-slider"
    And  I click "Submit Changes"
    And  I wait for "10" seconds
    And  I should see "ENTRY HAS BEEN UPDATED"
    And  I should see "Has been added"
    And  I click ".close"
    And  I wait for "2" seconds
    Then I click ".bfrp-inline-wlbl-6"
    And  I wait for "5" seconds
    And  take a screenshot
    And  Element with class "wlbl-entry-wlbl" should not have content "BL-med"
    And  Element with class "wlbl-entry-wlbl" should have content "WL-weak"
    And  clean up wlbl and remove all wlbl entries on "testing.com"



  @javascript
  Scenario: a user searches for a url on the research page and adds multiple results to a WBRS white list
    Given a user with role "webrep user" exists and is logged in
    And  clean up wlbl and remove all wlbl entries on "testing.com"
    And  clean up wlbl and remove all wlbl entries on "prooftesting.com"
    When I goto "escalations/webrep/research"
    And  I choose "research-search-strict"
    And  I type content "testing.com" within input with id "search_uri"
    Then I click "Submit"
    And  I wait for "60" seconds
    Then I check checkbox with class "bfrp-checkbox-4"
    And  I check checkbox with class "bfrp-checkbox-6"
    And  I click button "wlbl_entries_button"
    And  I wait for "5" seconds
    And  I should see "Not on a list"
    And  Element with class "bfrp-dd-result-no-0" should not have content "WL-weak"
    And  Element with class "bfrp-dd-result-no-1" should not have content "WL-weak"
    And  I choose "wlbl-add"
    And  I check checkbox with class "wl-weak-checkbox"
    And  I should not see "Threat Categories"
    And  I should not see "Bogon"
    And  I click "Submit Changes"
    And  I wait for "5" seconds
    And  I should see "ENTRIES HAVE BEEN UPDATED"
    And  I should see "Have been added"
    And  I click ".close"
    And  I wait for "2" seconds
    And  I click button "wlbl_entries_button"
    And  I wait for "5" seconds
    And  Element with class "bfrp-dd-result-no-0" should have content "WL-weak"
    And  Element with class "bfrp-dd-result-no-1" should have content "WL-weak"
    And  take a screenshot
    And  clean up wlbl and remove all wlbl entries on "testing.com"
    And  clean up wlbl and remove all wlbl entries on "prooftesting.com"


  @javascript
  Scenario: a user searches for a url on the research page and adds multiple results to a WBRS blacklist
    Given a user with role "webrep user" exists and is logged in
    And  clean up wlbl and remove all wlbl entries on "testing.com"
    And  clean up wlbl and remove all wlbl entries on "prooftesting.com"
    When I goto "escalations/webrep/research"
    And  I choose "research-search-strict"
    And  I type content "testing.com" within input with id "search_uri"
    Then I click "Submit"
    And  I wait for "60" seconds
    Then I check checkbox with class "bfrp-checkbox-4"
    And  I check checkbox with class "bfrp-checkbox-6"
    And  I click button "wlbl_entries_button"
    And  I wait for "5" seconds
    And  I should see "Not on a list"
    And  Element with class "bfrp-dd-result-no-0" should not have content "BL-weak"
    And  Element with class "bfrp-dd-result-no-1" should not have content "BL-weak"
    And  I choose "wlbl-add"
    And  I check checkbox with class "bl-weak-checkbox"
    And  I should see "Threat Categories"
    And  I should see "Bogon"
    And  I click ".wlbl_thrt_cat_id_8"
    And  I click "Submit Changes"
    And  I wait for "5" seconds
    And  I should see "ENTRIES HAVE BEEN UPDATED"
    And  I should see "Have been added"
    And  I click ".close"
    And  I wait for "2" seconds
    And  I click button "wlbl_entries_button"
    And  I wait for "5" seconds
    And  Element with class "bfrp-dd-result-no-0" should have content "BL-weak"
    And  Element with class "bfrp-dd-result-no-1" should have content "BL-weak"
    And  take a screenshot
    And  clean up wlbl and remove all wlbl entries on "testing.com"
    And  clean up wlbl and remove all wlbl entries on "prooftesting.com"



  @javascript
  Scenario: a user searches for a url on the research page and removes multiple results from a WBRS List
    Given a user with role "webrep user" exists and is logged in
    And  clean up wlbl and remove all wlbl entries on "testing.com"
    And  clean up wlbl and remove all wlbl entries on "prooftesting.com"
    When I goto "escalations/webrep/research"
    And  I choose "research-search-strict"
    And  I type content "testing.com" within input with id "search_uri"
    Then I hit enter within "#search_uri"
    And  I wait for "60" seconds
    And  take a screenshot
    Then I check checkbox with class "bfrp-checkbox-4"
    And  I check checkbox with class "bfrp-checkbox-6"
    And  I click button "wlbl_entries_button"
    And  I wait for "5" seconds
    And  I should see "Not on a list"
    And  Element with class "bfrp-dd-result-no-0" should not have content "BL-weak"
    And  Element with class "bfrp-dd-result-no-1" should not have content "BL-weak"
    And  I choose "wlbl-add"
    And  I check checkbox with class "bl-weak-checkbox"
    And  I should see "Threat Categories"
    And  I should see "Bogon"
    And  I click ".wlbl_thrt_cat_id_8"
    And  I click "Submit Changes"
    And  I wait for "5" seconds
    And  I should see "ENTRIES HAVE BEEN UPDATED"
    And  I should see "Have been added"
    And  I click ".close"
    And  I wait for "2" seconds
    And  I click button "wlbl_entries_button"
    And  I wait for "5" seconds
    And  Element with class "bfrp-dd-result-no-0" should have content "BL-weak"
    And  Element with class "bfrp-dd-result-no-1" should have content "BL-weak"
    # and now we remove
    And  I choose "wlbl-remove"
    And  I should not see "Threat Categories"
    And  I check checkbox with class "bl-weak-checkbox"
    And  I click "Submit Changes"
    And  I wait for "5" seconds
    And  I should see "ENTRIES HAVE BEEN UPDATED"
    And  I should see "Have been removed"
    And  I click ".close"
    And  I wait for "2" seconds
    And  I click button "wlbl_entries_button"
    And  I wait for "5" seconds
    And  Element with class "bfrp-dd-result-no-0" should not have content "BL-weak"
    And  Element with class "bfrp-dd-result-no-1" should not have content "BL-weak"
    And  take a screenshot
    And  clean up wlbl and remove all wlbl entries on "testing.com"
    And  clean up wlbl and remove all wlbl entries on "prooftesting.com"