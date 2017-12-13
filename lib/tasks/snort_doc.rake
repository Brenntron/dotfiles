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
    SnortDocPublisher.years.each do |year|
      publisher = SnortDocPublisher.new(year: year)
      publisher.download
    end
  end

  desc 'Update the cves table with all missing cve references.'
  task :update_cve_data => :environment do
    SnortDocPublisher.update_cve_data
  end

  desc 'Update TOBE publishes status on rules from input YML file from snort organization'
  task :update_snort_doc_status, [:filename] => :environment do |tt, args|
    raise 'requires [filename], example `rake update_snort_doc_status[Rule_Update.diff.yml]`' unless 0 < args.count
    # contents = File.open(args[:filename], 'r') do |file|
    #   file.read
    # end
    # # puts contents
    # input = YAML.load(contents)
    input = YAML.load_file(args[:filename])
    # puts input.inspect

    # puts input['modules'].inspect

    SnortDocPublisher.update_snort_doc_status('modules' => input['modules'], 'rules' => input['modules'])
  end

  task :snortdoc => :environment do

    rule = Rule.find 301

    cve_snort_docs = SnortDocPublisher.rule_snort_doc(rule)

    puts JSON.pretty_generate([cve_snort_docs])
  end
end
