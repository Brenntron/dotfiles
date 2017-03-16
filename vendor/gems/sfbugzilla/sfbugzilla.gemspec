Gem::Specification.new do |s|
  s.name        = 'sfbugzilla'
  s.version     = '0.1.6'
  s.date        = '2016-01-08'
  s.summary     = "SF Specific Bugzilla library"
  s.description = "SF Specific bugzilla library"
  s.authors     = ["Christopher McBee"]
  s.email       = 'cmcbee@sourcefire.com'
  s.files       = ["lib/sfbugzilla.rb"]
  s.executables = Dir.glob("bin/*").map {|b| File.basename(b) }
  s.add_dependency('ruby-bugzilla', '> 0.6.3')
  s.add_dependency('highline')
  s.add_dependency('mime-types')
  s.add_dependency('term-ansicolor')
end

