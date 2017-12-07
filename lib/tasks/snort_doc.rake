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
  task :update_nvd_cves => :environment do

    SnortDocPublisher.each_publisher do |publisher|
      publisher.download

      publisher.references.each do |ref_rec|
        cve_key = "CVE-#{ref_rec.reference_data}"
        nvd_cve_item = publisher.nvd_cve_item(cve_key)
        unless nvd_cve_item
          $stderr.puts "Cannot find NVD input data for #{cve_key.inspect}."
          next
        end

        cve_rec = ref_rec.build_cve(cve_key: cve_key, year: publisher.year)
        cve_rec.assign_attributes(nvd_cve_item.attributes)
        cve_rec.affected_systems = nvd_cve_item.affected_systems.join("\n")
        cve_rec.save!

        nvd_cve_item.each_reference do |ref_type_name, ref_data|
          ref_type = NvdCveItem.reference_type(ref_type_name)

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
  end
end
