require 'pry'
require 'rake'

namespace :data do

  task :add_service_status_records => :environment do

    service_data = [
      { name: "RULEAPI:CATEGORY", model: ""},
      { name: "RULEAPI:WEB_REPUTATION", model: ""},
      { name: "RULEAPI:CATEGORY_PREFIX", model: ""},
      { name: "RULEAPI:CATEGORY_HISTORY", model: ""},
      { name: "RULEAPI:CLUSTER", model: ""},
      { name: "RULEAPI:THREAT_CATEGORY", model: ""},


      { name: "RULEAPI:WSA_STATUS", model: ""},
      { name: "RULEAPI:RULEHIT", model: ""},
      { name: "RULEAPI:COMPLAINT_RECORD", model: ""},
      { name: "VIRUSTOTAL", model: ""},
      { name: "REPTOOL", model: ""},
      { name: "UMBRELLA:DOMAIN_INFO", model: ""},
      { name: "UMBRELLA:DOMAIN_VOLUME", model: ""},
      { name: "UMBRELLA:SCAN", model: ""},
      { name: "UMBRELLA:SECURITY_INFO", model: ""},
      { name: "UMBRELLA:WHOIS", model: ""},
      { name: "UMBRELLA:TIMELINE", model: ""}
    ]

    service_data.each do |service_status|
      ServiceStatus.find_or_create_by(name: service_status[:name]) do |s|
        s.model = service_status[:model]
        s.exception_count = 0
      end

    end


  end


end