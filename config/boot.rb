begin
  # use `bundle install --standalone' to get this...
  require_relative '..vendor/bundle/bundler/setup.rb'
  puts "USING STANDALONE BUNDLER"
rescue LoadError
  # fall back to regular bundler if the developer hasn't bundled standalone
  # Set up gems listed in the Gemfile.
  ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
  require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
  puts "USING NORMAL BUNDLER"
end


