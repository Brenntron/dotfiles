ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)
if ENV['RAILS_ENV'] != 'production' && ENV['RAILS_ENV'] != 'staging' && ENV['RAILS_ENV'] != 'freebsd'
  ENV['HOST'] = 'localhost'
end
require 'bundler/setup' # Set up gems listed in the Gemfile.
