require 'nvd_cve_item'
require 'snort_doc_publisher'


namespace :snortdoc do
  task :download_nvd, [:year] => :environment do |tt, args|
    SnortDocPublisher.new(args[:year]).download
  end

  task :update_nvd_cves => :environment do

    SnortDocPublisher.undoc_cve_refs_by_year.each_pair do |year, undoc_refs|
      publisher = SnortDocPublisher.new(year)
      publisher.download

      undoc_refs.each do |ref_rec|
        cve_key = "CVE-#{ref_rec.reference_data}"
        nvd_cve_item = publisher.nvd_cve_item(cve_key)

        cve_rec = ref_rec.build_cve(cve_key: cve_key, year: year)
        cve_rec.assign_attributes(nvd_cve_item.attributes)
        cve_rec.affected_systems = nvd_cve_item.affected_systems.join("\n")
        cve_rec.save!

        nvd_cve_item.each_reference do |ref_type_name, ref_data|
          ref_type = NvdCveItem.reference_types[ref_type_name]

          case
            when ref_type.blank?
              $stderr.puts "Unknown reference type '#{ref_type_name}'."
            when ref_rec.references.where(reference_type: ref_type, reference_data: ref_data).exists?
              # do nothing
            when Reference.where(reference_type: ref_type, reference_data: ref_data).exists?
              ref_rec.references << Reference.where(reference_type: ref_type, reference_data: ref_data).first
            else
              ref_rec.references.create(reference_type: ref_type, reference_data: ref_data)
          end
        end
      end
    end

    # year_cves = SnortDocPublisher.undoc_cve_refs_by_year['2013']
    # puts year_cves.inspect

    # curr_cve = year_cves.first
    # puts curr_cve
  end
end
