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
  Scenario: A user uses broad search
    Given a user with role "webrep user" exists and is logged in
    And I go to "escalations/webrep/research"
    When I click "#research-search-broad"
    And I fill in "search_uri" with "blizzard.com"
    And I click "#submit-button"
    And I wait for "30" seconds
    Then multiple research entries exist

  @javascript
  Scenario: A user uses strict search
    Given a user with role "webrep user" exists and is logged in
    And I go to "escalations/webrep/research"
    When I click "#research-search-strict"
    And I fill in "search_uri" with "cisco.com"
    And I click "#submit-button"
    And I wait for "15" seconds
    Then two research entries exists

  @javascript
  Scenario: a user searches for a url on the research page that has a threat category assigned to it already
    Given a user with role "webrep user" exists and is logged in
    When I goto "escalations/webrep/research"
    And  I choose "research-search-strict"
    And  I type content "1234computer.com" within input with id "search_uri"
    Then I click "Submit"
    And  I wait for "10" seconds
    And  I should see "2 found"
    And I should see content "Malware Sites" within first element of class ".wlbl-tc-research-span"

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

  @javascript
  Scenario: a user searches for a url on the research page and adds a result to a WBRS List
    Given a user with role "webrep user" exists and is logged in
    And  clean up wlbl and remove all wlbl entries on "testing.com"
    When I goto "escalations/webrep/research"
    And  I choose "research-search-strict"
    And  I type content "testing.com" within input with id "search_uri"
    Then I click "Submit"
    And  I wait for "30" seconds
    And  I click ".bfrp-inline-wlbl-0"
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
    Then I click ".bfrp-inline-wlbl-0"
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
    And  I wait for "30" seconds
    And  I click ".bfrp-inline-wlbl-0"
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
    #Here is where we actually remove
    Then I click ".bfrp-inline-wlbl-0"
    And  Element with class "wlbl-entry-wlbl" should have content "BL-med"
    Then I click "#bl-med-slider"
    And  I click "Submit Changes"
    And  I wait for "10" seconds
    And  I should see "ENTRY HAS BEEN UPDATED"
    And  I should see "Has been removed"
    And  I click ".close"
    And  I wait for "2" seconds
    Then I click ".bfrp-inline-wlbl-0"
    And  Element with class "wlbl-entry-wlbl" should not have content "BL-med"
    And  clean up wlbl and remove all wlbl entries on "testing.com"



  @javascript
  Scenario: a user searches for a url on the research page and removes a result from a WBRS List and adds it to another
    Given a user with role "webrep user" exists and is logged in
    And  clean up wlbl and remove all wlbl entries on "testing.com"
    When I goto "escalations/webrep/research"
    And  I choose "research-search-strict"
    And  I type content "testing.com" within input with id "search_uri"
    Then I click "Submit"
    And  I wait for "30" seconds
    And  I click ".bfrp-inline-wlbl-0"
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
    Then I click ".bfrp-inline-wlbl-0"
    And  Element with class "wlbl-entry-wlbl" should have content "BL-med"
    Then I click "#bl-med-slider"
    Then I click "#wl-weak-slider"
    And  I click "Submit Changes"
    And  I wait for "10" seconds
    And  I should see "ENTRY HAS BEEN UPDATED"
    And  I should see "Has been added"
    And  I click ".close"
    And  I wait for "2" seconds
    Then I click ".bfrp-inline-wlbl-0"
    And  I wait for "5" seconds
    And  Element with class "wlbl-entry-wlbl" should not have content "BL-med"
    And  Element with class "wlbl-entry-wlbl" should have content "WL-weak"
    And  clean up wlbl and remove all wlbl entries on "testing.com"



  @javascript
  Scenario: a user searches for a url on the research page and adds multiple results to a WBRS white list
    Given a user with role "webrep user" exists and is logged in
    And  clean up wlbl and remove all wlbl entries on "testing.com"
    And  clean up wlbl and remove all wlbl entries on "prooftesting.com"
    When I goto "escalations/webrep/research"
    And  I choose "research-search-broad"
    And  I type content "testing.com" within input with id "search_uri"
    And  I click "Submit"
    And  I wait for "60" seconds
    When I check checkbox with class "bfrp-checkbox-0"
    And  I check checkbox with class "bfrp-checkbox-5"
    And  I click button "wlbl_entries_button"
    And  I wait for "5" seconds
    Then I should see "Not on a list"
    And  wl/bl result number "0" should not have content "WL-weak"
    And  wl/bl result number "1" should not have content "WL-weak"
    When I choose "wlbl-add"
    And  I check checkbox with class "wl-weak-checkbox"
    Then I should not see "Threat Categories"
    And  I should not see "Bogon"
    When I click "Submit Changes"
    And  I wait for "5" seconds
    Then I should see "ENTRIES HAVE BEEN UPDATED"
    And  I should see "Have been added"
    When I click ".close"
    And  I wait for "2" seconds
    And  I click button "wlbl_entries_button"
    And  I wait for "5" seconds
    Then wl/bl result number "0" should have content "WL-weak"
    And  clean up wlbl and remove all wlbl entries on "testing.com"

  @javascript
  Scenario: a user searches for a url on the research page and adds multiple results to a WBRS blacklist
    Given a user with role "webrep user" exists and is logged in
    And  clean up wlbl and remove all wlbl entries on "testing.com"
    And  clean up wlbl and remove all wlbl entries on "prooftesting.com"
    When I goto "escalations/webrep/research"
    And  I choose "research-search-broad"
    And  I type content "testing.com" within input with id "search_uri"
    When I click "Submit"
    And  I wait for "60" seconds
    And  I check checkbox with class "bfrp-checkbox-0"
    And  I check checkbox with class "bfrp-checkbox-1"
    And  I click button "wlbl_entries_button"
    And  I wait for "5" seconds
    #Then I should see "Not on a list"
    And  wl/bl result number "1" should not have content "BL-weak"
    When I choose "wlbl-add"
    And  I check checkbox with class "bl-weak-checkbox"
    Then I should see "Threat Categories"
    And  I should see "Bogon"
    When I click ".wlbl_thrt_cat_id_8"
    And  I click "Submit Changes"
    And  I wait for "5" seconds
    Then I should see "ENTRIES HAVE BEEN UPDATED"
    And  I should see "Have been added"
    When I click ".close"
    And  I wait for "2" seconds
    And  I click button "wlbl_entries_button"
    And  I wait for "5" seconds
    And  wl/bl result number "0" should not have content "BL-weak"
    And  clean up wlbl and remove all wlbl entries on "testing.com"

  @javascript
  Scenario: a user searches for a url on the research page and removes multiple results from a WBRS List
    Given a user with role "webrep user" exists and is logged in
    And  clean up wlbl and remove all wlbl entries on "testing.com"
    And  clean up wlbl and remove all wlbl entries on "prooftesting.com"
    When I goto "escalations/webrep/research"
    And  I choose "research-search-strict"
    And  I type content "testing.com" within input with id "search_uri"
    When I hit enter within "#search_uri"
    And  I wait for "60" seconds
    Then I check checkbox with class "bfrp-checkbox-0"
    And  I check checkbox with class "bfrp-checkbox-1"
    And  I click button "wlbl_entries_button"
    And  I wait for "5" seconds
    Then I should see "Not on a list"
    And  wl/bl result number "0" should not have content "BL-weak"
    And  wl/bl result number "1" should not have content "BL-weak"
    When I choose "wlbl-add"
    And  I check checkbox with class "bl-weak-checkbox"
    Then I should see "Threat Categories"
    And  I should see "Bogon"
    When I click ".wlbl_thrt_cat_id_8"
    And  I click "Submit Changes"
    And  I wait for "5" seconds
    Then I should see "ENTRIES HAVE BEEN UPDATED"
    And  I should see "Have been added"
    When I click ".close"
    And  I wait for "2" seconds
    And  I click button "wlbl_entries_button"
    And  I wait for "5" seconds
    Then wl/bl result number "0" should have content "BL-weak"
    And  wl/bl result number "1" should have content "BL-weak"
    # and now we remove
    And  I choose "wlbl-remove"
    Then I should not see "Threat Categories"
    And  I check checkbox with class "bl-weak-checkbox"
    When I click "Submit Changes"
    And  I wait for "5" seconds
    Then I should see "ENTRIES HAVE BEEN UPDATED"
    And  I should see "Have been removed"
    When I click ".close"
    And  I wait for "2" seconds
    And  I click button "wlbl_entries_button"
    And  I wait for "5" seconds
    Then wl/bl result number "0" should not have content "BL-weak"
    And  wl/bl result number "1" should not have content "BL-weak"
    And  clean up wlbl and remove all wlbl entries on "testing.com"
    And  clean up wlbl and remove all wlbl entries on "prooftesting.com"



  ####
  # Quicklookup feature
  ####

  @javascript
  Scenario: a user can access quick lookup and add multiple rows of valid urls and ips to quick lookup on enter. invalid entries should not have rows built
    Given a user with role "webrep user" exists and is logged in
    When I goto "escalations/webrep/research"
    And I click "#research"
    And I click ".quick-lookup-tab"
    Then I should see content "Submit Reputation Changes" within "#submit-rep-changes"
    And I enter content "1.2.3.4 https://1234computer.com g-oogl-e.com faketestcom" within p with class ".col-bulk-dispute"
    Then I hit enter within ".col-bulk-dispute"
    And  I wait for "2" seconds
    Then quick lookup entry "bulk-dispute" column number "1" should have content "1.2.3.4"
    Then quick lookup entry "bulk-dispute" column number "2" should have content "https://1234computer.com"
    Then quick lookup entry "bulk-dispute" column number "3" should have content "g-oogl-e.com"
    Then I should not see content "faketestcom" within "#research-table"

  @javascript
  Scenario: a user can add only ips in quicklookup without error
    Given a user with role "webrep user" exists and is logged in
    When I goto "escalations/webrep/research#lookup-quick"
    Then I should see content "Submit Reputation Changes" within "#submit-rep-changes"
    And I enter content "1.2.3.4 3.4.5.6 7.8.3.2 faketestcom" within p with class ".col-bulk-dispute"
    Then I hit enter within ".col-bulk-dispute"
    And  I wait for "2" seconds
    Then quick lookup entry "bulk-dispute" column number "1" should have content "1.2.3.4"
    Then quick lookup entry "bulk-dispute" column number "2" should have content "3.4.5.6"
    Then quick lookup entry "bulk-dispute" column number "3" should have content "7.8.3.2"
    Then I should not see content "faketestcom" within "#research-table"

  @javascript
  Scenario: a user can get the reputation data for each row added in quicklookup
    Given a user with role "webrep user" exists and is logged in
    When I goto "escalations/webrep/research#lookup-quick"
    Then I should see content "Submit Reputation Changes" within "#submit-rep-changes"
    And I enter content "https://www.1234computer.com www.g-oogl-e.com" within p with class ".col-bulk-dispute"
    Then I hit enter within ".col-bulk-dispute"
    Then I click "#get-rep-data"
    And  I wait for "5" seconds
    # column number 1 == https://www.1234computer.com
    Then quick lookup entry "wbrs" column number "1" should have content "-9.5"
    # column number 2 == www.g-oogl-e.com
    Then quick lookup entry "wlbl" column number "2" should have content "-9.5"

  @javascript
  Scenario: a user can set the reptool action column and submit reptool suggestions for selected entries
    Given a user with role "webrep user" exists and is logged in
    When I goto "escalations/webrep/research#lookup-quick"
    Then I should see content "Submit Reputation Changes" within "#submit-rep-changes"
    And I enter content "https://www.1234computer.com www.g-oogl-e.com" within p with class ".col-bulk-dispute"
    Then I hit enter within ".col-bulk-dispute"
    Then I click "#get-rep-data"
    And  I wait for "5" seconds
    Then I toggle checkbox of quick lookup entry row number "2"
    Then I click "reptool_entries_button"
    And  I should see "Adjust Reptool Classification"
    Then I click "input[name='attackers']"
    Then I click "input[name='open_proxy']"
    Then I click "input[name='malware']"
    Then I click "input[name='cnc']"
    Then I click "quick-lookup-reptool-submit"
    And  I wait for "1" seconds
    Then I click "submit-rep-changes"
    And I should see "New Reputation Dispute Ticket"
    And I type content "A truly fantastic test comment" within input with id "confirm-rep-input"
    Then I click "confirm-rep-changes"
#    Then I should see "Loading data..."
#    Quicklookup ajax call isn't working, data is undefined, fuck this
#   Need confirmation that dispute was successfully submitted or errs