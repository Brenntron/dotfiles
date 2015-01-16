Feature: Subscription user interface
  In order to subscribe
  As a user
  I want to provide a subscription interface

  # === access ===
  Scenario: a user must be logged into view their subscription
    Given a "basic" user exists
    And I goto the current users subscription page
    Then I should see "not authorized"

  Scenario: a user can view their subscription
    Given a "basic" user exists and is signed in
    And I goto the current users subscription page
    Then I should be on "/users/1/subscriptions"

  Scenario: a user can not view an other users subscription
    Given a "basic" user exists and is signed in
    And the following users exist:
    | email         |
    | derp@derp.com |
    When I goto "/users/2/subscriptions"
    Then I should see "not authorized"

  Scenario: a user cannot update another users credit card
    Given a "basic" user exists and is signed in
    And the following users exist:
      | email         |
      | derp@derp.com |
    And the following cards exist:
      | user_id |
      | 2       |
    When I update "derp@derp.com" credit card
    Then I should see "not authorized"

  Scenario: a user cannot delete another users credit card
    Given a "basic" user exists and is signed in
    And the following users exist:
      | email         |
      | derp@derp.com |
    And the following cards exist:
      | user_id |
      | 2       |
    When I delete "derp@derp.com" credit card
    Then I should see "not authorized"

  Scenario: a user cannot create another users credit card
    Given a "basic" user exists and is signed in
    And the following users exist:
      | email         |
      | derp@derp.com |
    And the following cards exist:
      | user_id |
      | 2       |
    When I create "derp@derp.com" credit card
    Then I should see "not authorized"


  # === index ===
  Scenario: a new user starts with a free subscription
    Given a "basic" user exists and is signed in
    When I goto the current users subscription page
    Then I should see content "free" within "table"

  @javascript
  Scenario: a user can purchase a personal subscription
    Given a "basic" user exists and is signed in
    And I goto the current users subscription page
    And I click "Credit Card"
    And I choose "personalRadio"
    And I fill in "personalQuantity" with "1"
    When I click "Save"
    Then "#payment_modal" should be visible

    Given I fill in "card-number" with "4242424242424242"
    And I fill in "cvc" with "123"
    And I fill in "exp-month" with "1"
    And I fill in "exp-year" with next year
    And I check "accept-terms"
    When I click "Save"
    And I wait for "4" seconds
    Then "#subscription-change-modal" should be visible
    #wait for calculation
    And I wait for "4" seconds
    When I click "Ok"
    And I wait for "2" seconds
    Then I should see "Payment Method"
    And I should see content "personal" within "table"
    And I should see content "1" within "table"
    And the current users stripe subscription should match
    And the current users stripe card should match


  @javascript
  Scenario: a user can purchase a business subscription
    Given a "basic" user exists and is signed in
    And I goto the current users subscription page
    And I click "Credit Card"
    And I choose "businessRadio"
    And I fill in "businessQuantity" with "1"
    When I click "Save"
    Then "#payment_modal" should be visible

    Given I fill in "card-number" with "4242424242424242"
    And I fill in "cvc" with "123"
    And I fill in "exp-month" with "1"
    And I fill in "exp-year" with next year
    And I check "accept-terms"
    When I click "Save"
    Then I wait for "1" seconds
    Then "#subscription-change-modal" should be visible
    #wait for calculation
    And I wait for "4" seconds
    When I click "Ok"
    And I wait for "4" seconds
    Then I should see "Payment Method"
    And I should see content "business" within "table"
    And I should see content "1" within "table"
    And the current users stripe subscription should match
    And the current users stripe card should match


  @javascript
  Scenario: a user can upgrade their existing subscription
    Given a "basic" user exists and is signed in
    And the current user has a personal subscription
    And I goto the current users subscription page
    And I click "Credit Card"
    And I choose "personalRadio"
    And I fill in "personalQuantity" with "2"
    When I click "Save"
    And I wait for "3" seconds
    Then I should see "Confirm Subscription Change"
    And I should see either "You will be billed $29.91" or "You will be billed $29.99"

    When I click "Ok"
    Then I should see content "2" within "table"
    And the current users stripe subscription should match


  @javascript
  Scenario: a user can downgrade their subscription
    Given a "basic" user exists and is signed in
    And the current user has a personal subscription
    And I goto the current users subscription page
    And I click "Credit Card"
    And I choose "freeRadio"
    When I click "Save"
    And I wait for "3" seconds
    Then I should see "Confirm Subscription Change"
    And I should see "you will be charged $0"
    When I click "Ok"
    And I wait for "5" seconds
    Then I should see content "free" within "table"
    And the current users stripe subscription should match


  @javascript
  Scenario: a user can downgrade then upgrade on the same day
    Given a "basic" user exists and is signed in
    And the current user has a personal subscription
    And I goto the current users subscription page
    And I click "Credit Card"
    And I choose "freeRadio"
    And I click "Save"
    And I wait for "3" seconds
    And I click "Ok"
    And I wait for "4" seconds
    Then I should see content "free" within "table"
    And I click "Credit Card"
    And I choose "personalRadio"
    And I fill in "personalQuantity" with "1"
    When I click "Save"
    And I wait for "4" seconds
    Then I should see "We have prorated your current subscription"
    When I click "Ok"
    And I wait for "4" seconds
    Then I should see content "personal" within "table"
    And I should see content "1" within "table"
    And the current users stripe subscription should match


  @javascript
  Scenario: a user cannot use a declined card
    Given a "basic" user exists and is signed in
    And I goto the current users subscription page
    And I click "Credit Card"
    And I choose "personalRadio"
    And I fill in "personalQuantity" with "1"
    When I click "Save"
    Then "#payment_modal" should be visible

    Given I fill in "card-number" with "4000000000000002"
    And I fill in "cvc" with "123"
    And I fill in "exp-month" with "1"
    And I fill in "exp-year" with next year
    And I check "accept-terms"
    When I click "Save"
    Then I wait for "2" seconds
    And I should see "credit_card: Your card was declined."

  @javascript
  Scenario: a users card is accepted but fails payment
    Given a "basic" user exists and is signed in
    And I goto the current users subscription page
    And I click "Credit Card"
    And I choose "businessRadio"
    And I fill in "businessQuantity" with "1"
    When I click "Save"
    Then "#payment_modal" should be visible

    Given I fill in "card-number" with "4000000000000341"
    And I fill in "cvc" with "123"
    And I fill in "exp-month" with "1"
    And I fill in "exp-year" with next year
    And I check "accept-terms"
    When I click "Save"
    Then I wait for "1" seconds
    Then "#subscription-change-modal" should be visible
    #wait for calculation
    And I wait for "4" seconds
    When I click "Ok"
    And I wait for "4" seconds
    Then I should see "credit_card: Your card was declined."
    When I goto the current users subscription page
    Then I should see content "free" within "table"
    And I should see "341"

  Scenario: a user can see direct sale subscriptions
    Given a "basic" user exists and is signed in
    And the user "basic@test.com" has a valid "po" subscription
    And the user "basic@test.com" has an expired "integrator" subscription
    When I goto the current users subscription page
    And I should see content "free" within "table"
    And I should see content "po" within "table"
    And I should see content "integrator" within "table"

  Scenario: a user should not see direct sales if not ds subscription
    Given a "basic" user exists and is signed in
    When I goto the current users subscription page
    Then I should see content "free" within "table"
    And I should not see content "po" within "table"

  @now
  @javascript
  Scenario: a user can upgrade with a direct sale subscription
    Given a "basic" user exists and is signed in
    And the user "basic@test.com" has a valid "po" subscription
    When I goto the current users subscription page
    And I click "Credit Card"
    And I choose "personalRadio"
    And I fill in "personalQuantity" with "2"
    When I click "Save"
    Then "#payment_modal" should be visible

    Given I fill in "card-number" with "4242424242424242"
    And I fill in "cvc" with "123"
    And I fill in "exp-month" with "1"
    And I fill in "exp-year" with next year
    And I check "accept-terms"
    When I click "Save"
    And I wait for "4" seconds
    Then "#subscription-change-modal" should be visible
    #wait for calculation
    And I wait for "4" seconds
    When I click "Ok"
    And I wait for "2" seconds
    Then I should see "Payment Method"
    And I should see content "personal" within "table"
    And I should see content "2" within "table"
    And the current users stripe subscription should match
    And the current users stripe card should match
    And I should see content "po" within "table"
    And I should see content "1" within "table"

  #purchase edge cases

  @javascript
  Scenario: a user exists in stripe with no CC on file and upgrades
    Given a "basic" user exists and is signed in
    And the current user exists in stripe
    And the current user has a stripe personal trial subscription
    And I goto the current users subscription page
    And I click "Credit Card"
    And I choose "businessRadio"
    And I fill in "businessQuantity" with "1"
    When I click "Save"
    Then I wait for "4" seconds
    Then "#payment_modal" should be visible

    Given I fill in "card-number" with "4242424242424242"
    And I fill in "cvc" with "123"
    And I fill in "exp-month" with "1"
    And I fill in "exp-year" with next year
    And I check "accept-terms"
    When I click "Save"
    Then I wait for "1" seconds
    Then "#subscription-change-modal" should be visible
    #wait for calculation
    And I wait for "4" seconds
    When I click "Ok"
    And I wait for "4" seconds
    Then I should see "Payment Method"
    And I should see content "business" within "table"
    And I should see content "1" within "table"
    And the current users stripe subscription should match
    And the current users stripe card should match


  # a customer exists with a CC on file and upgrades  (tested by; a user can upgrade their existing subscription)
  @javascript
  Scenario: a user exists in stripe with no stripe subscription record
    Given a "basic" user exists and is signed in
    And the current user exists in stripe
    And I goto the current users subscription page
    And I click "Credit Card"
    And I choose "businessRadio"
    And I fill in "businessQuantity" with "1"
    When I click "Save"
    Then I wait for "5" seconds
    Then "#payment_modal" should be visible

    Given I fill in "card-number" with "4242424242424242"
    And I fill in "cvc" with "123"
    And I fill in "exp-month" with "1"
    And I fill in "exp-year" with next year
    And I check "accept-terms"
    When I click "Save"
    Then I wait for "1" seconds
    Then "#subscription-change-modal" should be visible
    #wait for calculation
    And I wait for "4" seconds
    When I click "Ok"
    And I wait for "4" seconds
    Then I should see "Payment Method"
    And I should see content "business" within "table"
    And I should see content "1" within "table"
    And the current users stripe subscription should match
    And the current users stripe card should match

  @javascript
  Scenario: a user exists with a CC in stripe but not locally
    Given a "basic" user exists and is signed in
    And the current user exists in stripe
    And the current user has a CC in stripe
    And I goto the current users subscription page
    And I click "Credit Card"
    And I choose "businessRadio"
    And I fill in "businessQuantity" with "1"
    When I click "Save"
    Then I wait for "4" seconds
    Then "#payment_modal" should be visible

    Given I fill in "card-number" with "4242424242424242"
    And I fill in "cvc" with "123"
    And I fill in "exp-month" with "1"
    And I fill in "exp-year" with next year
    And I check "accept-terms"
    When I click "Save"
    Then I wait for "1" seconds
    Then "#subscription-change-modal" should be visible
    #wait for calculation
    And I wait for "4" seconds
    When I click "Ok"
    And I wait for "4" seconds
    Then I should see "Payment Method"
    And I should see content "business" within "table"
    And I should see content "1" within "table"
    And the current users stripe subscription should match
    And the current users stripe card should match

  @javascript
  Scenario: a user down/upgrades with an invalid stripe customer record and no stripe subscription id
    Given a "basic" user exists and is signed in
    And the current users customer id is jacked up
    And the current users subscription was imported or manually created
    And I goto the current users subscription page
    And I click "Credit Card"
    And I choose "freeRadio"
    When I click "Save"
    And I wait for "4" seconds
    Then "#subscription-change-modal" should be visible
    When I click "Ok"
    And I wait for "4" seconds
    Then I should see content "free" within "table"
    And the current users stripe subscription should match

    Given I click "Credit Card"
    And I choose "personalRadio"
    When I click "Save"
    And I wait for "5" seconds
    Then "#payment_modal" should be visible

    Given I fill in "card-number" with "4242424242424242"
    And I fill in "cvc" with "123"
    And I fill in "exp-month" with "1"
    And I fill in "exp-year" with next year
    And I check "accept-terms"
    When I click "Save"
    And I wait for "2" seconds
    Then "#subscription-change-modal" should be visible

    When I click "Ok"
    And I wait for "4" seconds
    Then I should see content "personal" within "table"
    And I should see content "1" within "table"
    And the current users stripe subscription should match

  @javascript
  Scenario: a user exists with a subscription id mismatch
    Given a "basic" user exists and is signed in
    And the current user has a personal subscription
    And the current users subscription id is jacked up
    And I goto the current users subscription page
    And I click "Credit Card"
    And I choose "businessRadio"
    And I fill in "businessQuantity" with "1"
    When I click "Save"
    Then I wait for "2" seconds
    And I should see "does not have a subscription with ID"

  @javascript
  Scenario: a user exists with a stripe customer id mismatch
    Given a "basic" user exists and is signed in
    And the current user has a personal subscription
    And the current users customer id is jacked up
    And I goto the current users subscription page
    And I click "Credit Card"
    And I choose "businessRadio"
    And I fill in "businessQuantity" with "1"
    When I click "Save"
    Then I wait for "2" seconds
    And I should see "No such customer"

  # === payment method ===
  @javascript
  Scenario: a user can update their payment method
    Given a "basic" user exists and is signed in
    And the current user has a personal subscription
    And I goto the current users subscription page
    And I click "Update payment"
    And I fill in "card-number" with "5555555555554444"
    And I fill in "cvc" with "123"
    And I select "1" from "exp-month"
    And I select "next year" from "exp-year"
    When I click "Save"
    And I wait for "3" seconds
    Then I should see "4444"
    And the current users stripe card should match

  @javascript
  Scenario: a user cannot update their payment when declined
    Given a "basic" user exists and is signed in
    And the current user has a personal subscription
    And I goto the current users subscription page
    And I click "Update payment"
    And I fill in "card-number" with "4000000000000002"
    And I fill in "cvc" with "123"
    And I select "1" from "exp-month"
    And I select "next year" from "exp-year"
    When I click "Save"
    And I wait for "3" seconds
    Then I should see "credit_card: Your card was declined."
    And the current users stripe card should match

  @javascript
  Scenario: a user will see payment expired notice
    Given a "basic" user exists and is signed in
    And the current user has a personal subscription
    And the current users card is expired
    When I goto the current users subscription page
    Then I should see "Payment method expired"

  @javascript
  Scenario: a user will see payment issues notices
    Given a "basic" user exists and is signed in
    And the current user has a personal subscription
    And the current user has payment events
    When I goto the current users subscription page
    Then I should see "Charge error"

  @javascript
  Scenario: payment issues will be hidden after update
    Given a "basic" user exists and is signed in
    And the current user has a personal subscription
    And the current user has payment events
    And I goto the current users subscription page
    And I click "Update payment"
    And I fill in "card-number" with "5555555555554444"
    And I fill in "cvc" with "123"
    And I select "1" from "exp-month"
    And I select "next year" from "exp-year"
    When I click "Save"
    And I wait for "3" seconds
    Then I should see "4444"
    And I should not see "Charge error"
    And the current users stripe card should match

  @javascript
  Scenario: a user will see empty payment notice
    Given a "basic" user exists and is signed in
    And the current users subscription was imported or manually created
    When I goto the current users subscription page
    Then I should see "Please update your payment method"

  @javascript
  Scenario: a user can update an empty payment method
    Given a "basic" user exists and is signed in
    And the current users subscription was imported or manually created
    And I goto the current users subscription page
    And I click "Update payment"
    And I fill in "card-number" with "5555555555554444"
    And I fill in "cvc" with "123"
    And I select "1" from "exp-month"
    And I select "next year" from "exp-year"
    When I click "Save"
    And I wait for "3" seconds
    Then I should see "4444"
    And I should not see "5555"
    And the current users stripe card should match

   #  === subscribe url ===
   Scenario: a guest user will be redirected to login page
     Given I goto "/subscribe"
     Then I should be on "/users/sign_in"

   Scenario: a current user will be redirected to subscription page
     Given a "basic" user exists and is signed in
     When I goto "/subscribe"
     Then I should be on the current users subscription page

