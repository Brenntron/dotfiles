require 'nvd_cve_item'
require 'snort_doc_publisher'


namespace :snortdoc do
  task :download_nvd, [:year] => :environment do |tt, args|
    SnortDocPublisher.new(args[:year]).download
  end

  task :update_nvd_cves => :environment do

    SnortDocPublisher.undoc_cve_refs_by_year.each_pair do |year, refs|
      publisher = SnortDocPublisher.new(year)

      publisher.download

      cve_key = publisher.nvd_cve_items.first['cve']['CVE_data_meta']['ID']

      nvd_cve_item = publisher.nvd_cve_item(cve_key)
      puts "--------------------------------------------------------------------------------"
      nvd_cve_item.each_reference do |ref_type, ref|
        if nvd_cve_item.reference_types[ref_type]
        else
          $stderr.puts "Unknown reference type #{ref_type}."
        end
      end
      exit
    end

    year_cves = SnortDocPublisher.undoc_cve_refs_by_year['2013']
    # puts year_cves.inspect

    curr_cve = year_cves.first
    puts curr_cve
  end
end
