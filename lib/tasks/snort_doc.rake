require 'nvd_cve_item'
require 'snort_doc_publisher'


# Force a download of a given NVD year
# Populate the cves table with all the CVEs we have references for, but have no record in the cves table.
# Include or exclude a rule from the snort documentation set
# Generate and upload an update to snort.org for a given list of rules.
# Suppress or un-suppress a CVE from updating manually.
# Auto-suppress a CVE after three failed attempts.

namespace :snortdoc do
  desc "Download one given year file from NIST NVD."
  task :download_nvd_year, [:year] => :environment do |tt, args|
    raise 'requires [year], example `rake download_nvd_year[2010]`' unless 0 < args.count
    SnortDocPublisher.new(year: args[:year]).download
  end

  desc "Download all the year files from NIST NVD for cve references we do not have cves records for."
  task :download_missing_nvd => :environment do
    SnortDocPublisher.years.each do |year|
      publisher = SnortDocPublisher.new(year: year)
      publisher.download
    end
  end

  desc "Update the cves table with all missing cve references."
  task :update_cve_data => :environment do
    SnortDocPublisher.update_cve_data
  end

  task :snortdoc => :environment do
    ref = Reference.cves.first
    puts "*** ref = #{ref.inspect}"

    rule = ref.rules.first
    puts "*** rule = #{rule.inspect}"
    puts "*** rule_content = #{rule.rule_content.inspect}"

    cve_refs = rule.references.cves
    puts "*** cves = #{cve_refs.inspect}"

    # cve = Cve.first
    # puts "*** cve = #{cve.inspect}"
  end
end
