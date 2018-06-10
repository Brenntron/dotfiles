# IMPORTANT: This file is generated by cucumber-rails - edit at your own peril.
# It is recommended to regenerate this file in the future when you upgrade to a
# newer version of cucumber-rails. Consider adding your own code to a new file
# instead of editing this one. Cucumber will automatically load all features/**/*.rb
# files.

require 'cucumber/api_steps'


if ENV['COVERAGE'] && ("0" != ENV['COVERAGE'])
  require 'simplecov'
  SimpleCov.start do
    add_filter %r{^/config}
    add_filter %r{^/vendor}
    add_filter %r{^/test}
    add_filter %r{^/features}
    add_filter %r{^/spec}
    add_filter %r{^/app/processors}

    add_group "Controllers", %r{app/controllers(?!/api)}
    add_group "Models", "app/models"
    add_group "API", "app/controllers/api"
    add_group "Helpers", "app/helpers"
    add_group "Serializers", "app/serializers"

    merge_timeout 3600
  end
end

require 'cucumber/rails'
require 'json'
require 'capybara/poltergeist'
require 'paper_trail/frameworks/cucumber'
require 'will_paginate/array'

Capybara.javascript_driver = :poltergeist
# Capybara defaults to CSS3 selectors rather than XPath.
# If you'd prefer to use XPath, just uncomment this line and adjust any
# selectors in your step definitions to use the XPath syntax.
# Capybara.default_selector = :xpath

# By default, any exception happening in your Rails application will bubble up
# to Cucumber so that your scenario will fail. This is a different from how
# your application behaves in the production environment, where an error page will
# be rendered instead.
#
# Sometimes we want to override this default behaviour and allow Rails to rescue
# exceptions and display an error page (just like when the app is running in production).
# Typical scenarios where you want to do this is when you test your error pages.
# There are two ways to allow Rails to rescue exceptions:
#
# 1) Tag your scenario (or feature) with @allow-rescue
#
# 2) Set the value below to true. Beware that doing this globally is not
# recommended as it will mask a lot of errors for you!
#
ActionController::Base.allow_rescue = false

# Remove/comment out the lines below if your app doesn't have a database.
# For some databases (like MongoDB and CouchDB) you may need to use :truncation instead.
begin
  DatabaseCleaner.strategy = :truncation
  DatabaseCleaner.clean_with(:truncation)
rescue NameError
  raise "You need to add database_cleaner to your Gemfile (in the :test group) if you wish to use it."
end

# You may also want to configure DatabaseCleaner to use different strategies for certain features and scenarios.
# See the DatabaseCleaner documentation for details. Example:
#
#   Before('@no-txn,@selenium,@culerity,@celerity,@javascript') do
#     # { :except => [:widgets] } may not do what you expect here
#     # as Cucumber::Rails::Database.javascript_strategy overrides
#     # this setting.
#     DatabaseCleaner.strategy = :truncation
#   end
#
#   Before('~@no-txn', '~@selenium', '~@culerity', '~@celerity', '~@javascript') do
#     DatabaseCleaner.strategy = :transaction
#   end
#

Before('@debug') do
  options = {:js_errors => true, :inspector => true}
  Capybara.register_driver :poltergeist do |app|
    Capybara::Poltergeist::Driver.new(app,options)
  end
end

Before('@no-js-errors') do
  Capybara.register_driver :poltergeist do |app|
    options = {js_errors: false}
    Capybara::Poltergeist::Driver.new(app,options)
  end
end


# Possible values are :truncation and :transaction
# The :transaction strategy is faster, but might give you threading problems.
# See https://github.com/cucumber/cucumber-rails/blob/master/features/choose_javascript_database_strategy.feature
Cucumber::Rails::Database.javascript_strategy = :truncation

