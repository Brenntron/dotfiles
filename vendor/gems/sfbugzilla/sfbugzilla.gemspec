Gem::Specification.new do |s|
  s.name        = 'sfbugzilla'
  s.version     = '0.0.10'
  s.date        = '2013-03-18'
  s.summary     = "SF Specific Bugzilla library"
  s.description = "SF Specific bugzilla library"
  s.authors     = ["Christopher McBee"]
  s.email       = 'cmcbee@sourcefire.com'
  s.files       = ["lib/sfbugzilla.rb"]
  s.add_dependency('ruby-bugzilla', '>= 0.6.0')
  s.add_dependency('highline', '>= 1.6.8')
  s.add_dependency('mime-types', '>= 1.18')
end

