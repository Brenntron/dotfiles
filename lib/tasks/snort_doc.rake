require 'nvd_cve_item'
require 'snort_doc_publisher'

namespace :snortdoc do
  desc 'Download one given year file from NIST NVD.'
  task :download_nvd_year, [:year] => :environment do |tt, args|
    raise 'requires [year], example `rake download_nvd_year[2010]`' unless 0 < args.count
    SnortDocPublisher.new(year: args[:year]).download
  end

  desc 'Download all the year files from NIST NVD for cve references we do not have cves records for.'
  task :download_missing_nvd => :environment do
    SnortDocPublisher.download_all
  end

  desc 'Update the cves table with all missing cve references.'
  task :update_cve_data => :environment do
    SnortDocPublisher.update_cve_data
  end

  desc 'Update TOBE publishes status on rules from input YML file from snort organization'
  task :update_snort_doc_status, [:filename] => :environment do |tt, args|
    raise 'requires [filename], example `rake update_snort_doc_status[Rule_Update.diff.yml]`' unless 0 < args.count
    SnortDocPublisher.update_snort_doc_to_be(YAML.load_file(args[:filename]))
  end

  desc 'Generate Snort Rule Docs written to stdout from optional filename'
  task :gen_snort_doc_no_update, [:filename] => :environment do |tt, args|
    puts JSON.pretty_generate(SnortDocPublisher.gen_snort_doc(args[:filename]))
  end

  desc 'Update cves from NVD and generate Snort Rule Docs written to stdout from optional filename'
  task :gen_snort_doc, [:filename] => [:environment, :update_cve_data] do |tt, args|
    Rake::Task["snortdoc:gen_snort_doc_no_update"].invoke(args[:filename])
  end
end
