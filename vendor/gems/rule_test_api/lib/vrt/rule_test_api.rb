require 'her'

# Main class for accessing the RuleTestAPI Service. 
#
# ==== Examples
#
#   # Initialize the RuleTestAPI library to use the current API service
#   RuleTestAPI.init('http://stewie.vrt.sourcefire.com:3389')
#
#   # Loop through all of the engine types
#   EngineType.all.each do {|et| puts et.name }
#
#   # Find a specific engine type
#   engine_type = EngineType.find_by_name('Persistent')
#
#   # Find a specific snort configuration
#   snort_config = SnortConfiguration.find_by_name('Open Source')
#
# See examples/run_pcap.rb for more examples of how to use this library.

class RuleTestAPI

  # Initialize the RuleTestAPI with the URL to the API service.
  def self.init(url)
    
    # Setup her first
    Her::API.setup url: url do |c|
      c.use Faraday::Request::UrlEncoded
      c.use Her::Middleware::DefaultParseJSON
      c.use Faraday::Adapter::NetHttp
    end
    
    # Now we can include all of the subclasses
    require 'vrt/rule_test_api/engine_type'
    require 'vrt/rule_test_api/engine'
    require 'vrt/rule_test_api/snort_configuration'
    require 'vrt/rule_test_api/rule_configuration'
    require 'vrt/rule_test_api/job'
    require 'vrt/rule_test_api/pcap_test'
    require 'vrt/rule_test_api/pcap'
    require 'vrt/rule_test_api/alert'
    require 'vrt/rule_test_api/rule'

  end
end
