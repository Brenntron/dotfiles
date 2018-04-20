Gem::Specification.new do |spec|
  spec.name        = 'peake-bridge-client'
  spec.version     = '0.0.5.0'
  spec.date        = '2018-03-14'
  spec.summary     = "Talos web app gateway"
  spec.description = "Messaging service among Talos web apps"
  spec.authors     = ["Marlin Pierce", "Nicolette Verbeck"]
  spec.email       = 'marlpier@cisco.com'
  spec.files       = ["LICENSE", "lib/peake-bridge-client.rb", "lib/peake-bridge-client/basic_peake_bridge.rb"]
  spec.homepage    = 'https://www.cisco.com/c/en/us/products/security/talos.html'
  spec.license     = 'Nonstandard'
  spec.rdoc_options += %w[-x .*]

  spec.add_dependency('json', '>= 1.8.0', '< 3.0')
  # spec.add_dependency('gssapi', '~> 1.2.0')
end

