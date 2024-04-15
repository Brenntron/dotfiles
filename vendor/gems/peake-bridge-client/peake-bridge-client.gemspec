Gem::Specification.new do |spec|
  spec.name        = 'peake-bridge-client'
  spec.version     = '0.2.0.2'
  spec.date        = '2023-09-05'
  spec.summary     = "Talos web app gateway"
  spec.description = "Messaging service among Talos Atlas Group web apps"
  spec.authors     = ["Marlin Pierce", "Nicolette Verbeck", "Nick Herbert"]
  spec.email       = 'marlpier@cisco.com'
  spec.files       = ["LICENSE", "lib/peake-bridge-client.rb", "lib/peake-bridge-client/basic_peake_bridge.rb", "peake-bridge-client.gemspec"]
  spec.homepage    = 'https://www.cisco.com/c/en/us/products/security/talos.html'
  spec.license     = 'Nonstandard'
  spec.rdoc_options += %w[-x .*]

  spec.add_dependency('json',  '>= 2.6.2')
  spec.add_dependency('httpi', '>= 2.4.2')
  spec.add_dependency('curb',  '>= 0.9')
  spec.add_dependency('openssl', '>= 2.1.4')

end

