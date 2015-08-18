require 'find'

Gem::Specification.new do |s|
  s.name                          = 'rule_test_api'
  s.version                       = '0.1.4'
  s.date                          = '2014-08-21'
  s.summary                       = 'Library used for accessing the rule testing API'
  s.description                   = 'Library used for accessing the rule testing API'
  s.authors                       = ['Christopher McBee']
  s.email                         = 'cmcbee@sourcefire.com'

  Find.find("lib") do |path|
    if path =~ /\.rb$/
      s.files << path
    end
  end

  s.add_dependency('her', '>= 0.7.2')
end