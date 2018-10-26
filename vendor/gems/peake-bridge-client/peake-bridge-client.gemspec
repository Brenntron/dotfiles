Gem::Specification.new do |spec|
  spec.name        = 'peake-bridge-client'
  spec.version     = '0.0.9.0'
  spec.date        = '2018-10-24'
  spec.summary     = "Talos web app gateway"
  spec.description = "Messaging service among Talos web apps"
  spec.authors     = ["Marlin Pierce", "Nicolette Verbeck", "Nick Herbert"]
  spec.email       = 'marlpier@cisco.com'
  spec.files       = ["LICENSE", "lib/peake-bridge-client.rb", "lib/peake-bridge-client/basic_peake_bridge.rb"]
  spec.homepage    = 'https://www.cisco.com/c/en/us/products/security/talos.html'
  spec.license     = 'Nonstandard'
  spec.rdoc_options += %w[-x .*]

  spec.add_dependency('json',  '>= 1.8.0', '< 3.0')
  spec.add_dependency('httpi', '~> 2.4')
  spec.add_dependency('curb',  '~> 0.9')
  spec.add_dependency('openssl', '~> 2.1', '>= 2.1.2')

end

