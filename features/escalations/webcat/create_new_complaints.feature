Feature: Webcat create new complaints

  @javascript
  Scenario: a user can manually create a new complaint
    Given a user with role "webcat user" exists and is logged in
    And bugzilla rest api always saves
    And complaint entry preload is stubbed
    And WBRS top url is stubbed
    And WBRS Prefix where is stubbed
    And the following platforms exist:
      | id | public_name       | internal_name     | webcat |
      | 1  | TalosIntelligence | TalosIntelligence | 1      |
      | 3  | FirePower         | NGFW              | 1      |
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#new-complaint"
    And I fill in "ips_urls" with "talosintelligence.com"
    And I fill in "description" with "This is my favorite website"
    And I fill in "platforms" with "TalosIntelligence"
    And I click "Create"
    And I wait for "5" seconds
    And I should see "THE FOLLOWING 1 COMPLAINTS WERE SUCCESSFULLY CREATED"


  @javascript
  Scenario: a user can manually create a new complaint that is uppercased and the path will become lowercased
    Given a user with role "webcat user" exists and is logged in
    And bugzilla rest api always saves
    And complaint entry preload is stubbed
    And WBRS top url is stubbed
    And WBRS Prefix where is stubbed
    And the following platforms exist:
      | id | public_name       | internal_name     | webcat |
      | 1  | TalosIntelligence | TalosIntelligence | 1      |
    And I goto "/escalations/webcat/complaints?f=ALL"
    And I click "#new-complaint"
    And I fill in "ips_urls" with "TalosIntelligence.com/my_FUNKY_url?is=Baller"
    And I fill in "description" with "This is my favorite website"
    And I fill in "platforms" with "TalosIntelligence"
    And I click "Create"
    And I wait for "5" seconds
    And I should see "THE FOLLOWING 1 COMPLAINTS WERE SUCCESSFULLY CREATED"
    And I click ".close"
    Then I wait for "10" seconds
    And I should see "talosintelligence.com"


