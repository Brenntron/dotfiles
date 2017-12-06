require 'nvd_cve_item'
require 'snort_doc_publisher'


namespace :snortdoc do
  task :speak => :environment do
    puts "Hello world!"

    set = SnortDoc::PublishSet.new
    puts set.sids.inspect

    puts SnortDocPublisher.inspect
  end

  task :download_nvd, [:year] => :environment do |tt, args|
    SnortDocPublisher.new(args[:year]).download
  end

  task :update_nvd_cves => :environment do

    SnortDocPublisher.undoc_cve_refs_by_year.each_pair do |year, refs|
      publisher = SnortDocPublisher.new(year)

      publisher.download

      cve_key = publisher.nvd_cve_items.first['cve']['CVE_data_meta']['ID']
      # puts publisher.nvd_cve_items.first.inspect
      puts cve_key.inspect

      nvd_cve_item = publisher.nvd_cve_item(cve_key)
      # puts publisher.nvd_cve_item(cve_key).inspect
      puts "description = #{nvd_cve_item.description.inspect}"
      puts "base_score = #{nvd_cve_item.base_score.inspect}"
      puts "impact_score = #{nvd_cve_item.impact_score.inspect}"
      puts "exploit_score = #{nvd_cve_item.exploit_score.inspect}"
      puts "confidentiality_impact = #{nvd_cve_item.confidentiality_impact.inspect}"
      puts "integrity_impact = #{nvd_cve_item.integrity_impact.inspect}"
      puts "availability_impact = #{nvd_cve_item.availability_impact.inspect}"
      puts "--------------------------------------------------------------------------------"
      puts nvd_cve_item.affected_systems.join("\n")
      exit
    end

    year_cves = SnortDocPublisher.undoc_cve_refs_by_year['2013']
    # puts year_cves.inspect

    curr_cve = year_cves.first
    puts curr_cve
  end
end
