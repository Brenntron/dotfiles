FactoryBot.define do
  factory :reference_type do
    name            { 'cve' }
    description     { 'Common Vulnerabilities and Exposures' }
    validation      { '^(19|20)\\d{2}-\\d{4}$' }
    bugzilla_format { 'cve-((19|20)\\d{2}-\\d{4})' }
    example         { '1999-1234' }
    rule_format     { 'cve,<reference>' }
    url             { 'http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-DATA' }

    factory :cve_reference_type do
      name          { 'cve' }
    end

    factory :url_reference_type do
      name          { 'url' }
    end
  end
end
