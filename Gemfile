source 'https://rubygems.org'

ruby "3.0.6"

# Web-framework
gem 'rack', '>= 2.2.4'
gem 'rails', '6.1.7'
gem 'rack-cors', '0.4.1', require: 'rack/cors'
gem 'active_model_serializers', '0.10.12'
gem 'grape', '1.6.2'
gem 'grape-swagger', '0.31.1'
gem 'grape-swagger-rails', '0.5.0'
gem 'grape-active_model_serializers', '1.5.2'
gem 'hashie-forbidden_attributes', '~> 0.1.1'
gem 'activerecord-session_store', '2.1.0'
gem 'simple_form', '4.0.1'

# Asset Pipeline
gem 'haml', '~> 5.2.2'
gem 'uglifier', '4.1.20'
gem 'jquery-rails', '~> 4.3'
gem 'jquery-ui-rails', '~> 6.0'
gem 'coffee-rails', '5.0.0'
gem 'bootstrap-multiselect-rails', '~> 0.9.9'
gem 'bootstrap-sass', '~> 3.4.1'
gem "sassc", '2.4.0'
gem "sassc-rails", '~> 2.0'
# gem 'libv8', '3.16.14.19'
gem 'turbolinks', '5.2.0'
gem "sprockets", '~> 3.7.1'
gem 'jbuilder', '2.9.0'
gem 'inline_svg', '1.3.1'
gem 'selectize-rails', '~> 0.12.4'

# Database
gem 'mysql2'
gem 'paper_trail', '12.0.0'
gem 'rails_admin', '~> 2.2.1'
gem 'redis'

# Security
gem 'cancancan', '3.3.0'
gem 'grape-cancan', '0.0.2'
gem 'devise', '~> 4.5'

# Networking and Messaging
gem 'net-ldap', '0.16.1'
gem 'httpi'
gem 'her', '1.0.3'
gem 'curb', '1.0.5' #Libcurl bindings for Ruby
gem 'net-ssh', '5.0.2'
# next 4 gems were added to avoid 'already initialized constant' warning
# feel free to remove those lines and see those warnings all the time :)
gem "net-http"
gem "net-smtp"
gem "net-imap"
gem "uri", "0.12.0"
gem 'httparty', '~> 0.15.3'

gem 'peake-bridge-client', '~> 0.2.1' , path: 'vendor/gems/peake-bridge-client'

gem 'stomp', '1.4.6'
#gem 'aws-sdk', '2.11.170'
gem 'aws-sdk-s3', '1.117.2'
gem 'grpc', '1.56.0'
gem 'grpc-tools', '1.45.0'

# Bugzilla
gem 'xmlrpc'
gem 'bugzilla', require: 'bugzilla'

# Jira
gem 'jira-ruby', '2.3.0'

# Formatting and Presentation
gem 'nokogiri', '1.15.3'
gem 'diffy', '3.2.1'
gem 'gzip', '1.0'
gem 'chart-js-rails', '~> 0.1.7'
gem 'chartkick', '~> 2.2.4'
gem 'awesome_nested_set', '3.5.0'
gem 'will_paginate', '3.3.1'
gem 'kaminari', '1.1.1'
gem 'jquery-datatables', '~> 1.10.19'
gem 'ajax-datatables-rails', '~> 1.0.0'
gem 'rmagick', '5.0.0'
gem 'psych', '3.2.0'
gem 'rubyXL', '3.3.30'


# System Management
gem 'foreman', '0.86.0'
gem 'daemons', '1.2.6'
gem 'dalli', '2.7.9'
gem 'dotenv-rails', '2.8.0'
gem 'with_advisory_lock', '~> 4.0'
gem 'delayed_job', '4.1.9'
gem 'delayed_job_active_record', '4.1.7'
gem 'delayed_job_web', '1.4.3'

# Micellaneous
gem 'pry', '0.12.2'
gem 'pry-remote', '~> 0.1.8'

gem 'clipboard-rails', '1.7.1'

gem 'poltergeist', '1.18.1'
gem 'webdrivers', '5.2.0'

gem 'public_suffix', '4.0.7'
gem 'addressable', '~> 2.8.0'

gem 'dotiw'

gem 'elasticsearch'
gem 'hashie'

gem 'mail'
gem 'simpleidn'

gem 'symmetric-encryption', require: false
gem 'vault'

group :production, :staging do
  gem 'elastic-apm', '4.5.0'
end

group :development do
  gem 'puma', '6.0.0'
  gem 'awesome_print', '1.8.0'
  gem 'guard','2.14.2'

end

group :development, :test do
  gem 'byebug', '10.0.2'
end

group :test do
  gem 'factory_bot', '4.11.1'
  gem 'factory_bot_rails', '4.11.1'
  gem 'cucumber-rails', '2.6.1', require: false
  gem 'database_cleaner', '1.7.0'
  gem 'launchy', '~> 2.4.2'
  gem 'rb-fsevent', '0.10.3'
  gem 'rspec-rails', '4.0.1'
  gem 'faker', '1.9.1'
  # gem 'json_spec', '1.1.5' # cannot find any usage of this one, last updated in 2017
  gem 'simplecov', '0.16.1', :require => false
  gem "timecop"
  gem 'selenium-webdriver'
  gem 'rexml', '3.2.5'
end


