require 'snort_doc_publisher'

namespace :snortdoc do
  task :speak => :environment do
    puts "Hello world!"

    set = SnortDoc::PublishSet.new
    puts set.sids.inspect

    puts SnortDocPublisher.inspect
  end

  task :download_nvd, [:year] => :environment do |tt, args|
    SnortDocPublisher.new.download(args[:year])
  end

  task :update_nvd_cves => :environment do
    publisher = SnortDocPublisher.new

    publisher.undoc_cve_refs_by_year.each_pair do |year, refs|
      publisher.download(year)
    end

    year_cves = publisher.undoc_cve_refs_by_year['2013']
    # puts year_cves.inspect

    curr_cve = year_cves.first
    puts curr_cve
  end
end
