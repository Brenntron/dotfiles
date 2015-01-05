require 'crack'
require 'open-uri'
require 'pp'

class OSVDB
	def initialize(api_key, cve=nil)
		@api_key = api_key
		search_by_cve(cve) if cve
	end

	def search_by_cve(cve)
		#@data = Crack::XML.parse(URI.parse("http://osvdb.org/api/find_by_cve/#{@api_key}/#{cve}").read)
		@data = Crack::XML.parse(Rails.root.join('extras', 'page').to_s)
	end
	
	def references
		references = {}

		if not @data['vulnerabilities'].nil?
			@data['vulnerabilities'].each do |vuln|

				if not vuln['ext_references'].nil?
					vuln['ext_references'].each do |ref|
						
						type = ref['ext_reference_type_id']
						references[type] = [] if references[type].nil?
						references[type] << ref['value']
					end
				end
			end
		end

		return references
	end
end
