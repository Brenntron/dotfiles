class SnortDocPublisher
  attr_reader :year, :references

  # @return [ActiveRecord::Relation<Reference>] cve references with missing cves records.
  def self.undoc_cve_refs
    @undoc_cve_refs ||= Reference.cves.left_joins(:cve).where(cves: {id: nil})
  end

  # @return [Hash<String => Array<Reference>>] cve references with missing cves records grouped by year.
  def self.undoc_cve_refs_by_year
    @undoc_cve_refs_by_year ||= undoc_cve_refs.inject({}) do |result, ref|
      year = ref.reference_data.sub(/\A(\d{4})-\d+\z/, '\\1')
      if year < '2002'
        year = '2002'
      end
      year

      result[year] ||= []
      result[year] << ref
      result
    end
  end

  # @yield [SnortDocPublisher] Publishers for cve references with missing cves records.
  def self.each_publisher
    SnortDocPublisher.undoc_cve_refs_by_year.each_pair do |year, undoc_refs|
      yield SnortDocPublisher.new(year: year, references: undoc_refs)
    end
  end

  def each_missing
    references.each do |ref_rec|
      cve_key = "CVE-#{ref_rec.reference_data}"
      nvd_cve_item_curr = nvd_cve_item(cve_key)
      unless nvd_cve_item_curr
        $stderr.puts "Cannot find NVD input data for #{cve_key.inspect}."
        next
      end

      yield cve_key, ref_rec, nvd_cve_item_curr
    end
  end

  def self.years
    undoc_cve_refs_by_year.keys
  end

  # @params [String] year the given year for the CVEs to be updated
  def initialize(year:, references: [])
    @year = year
    @references = references
  end

  def filename
    "nvdcve-1.0-#{@year}.json"
  end

  def filepath
    Rails.root.join("lib/data/nvd/#{filename}")
  end

  def self.current_year
    @current_year ||= Time.now.year
  end

  # @return true if NVD data file for the year needs to be downloaded
  def download?
    case
      when year.to_i >= self.class.current_year
        true
      when File.exist?(filepath)
        false
      else
        true
    end
  end

  def download
    if download?
      cmd = "curl https://static.nvd.nist.gov/feeds/json/cve/1.0/#{filename}.gz > #{filepath}.gz"
      puts cmd
      # system(cmd)
      cmd = "gunzip -f #{filepath}.gz"
      puts cmd
      # system(cmd)
    end
  end

  # @return [Array<Hash>] data read from the year of NVD data file.
  def nvd_cve_items
    @nvd_cve_items ||= File.open(filepath, 'r') do |file|
      filedata = JSON.parse(file.read)
      filedata['CVE_Items']
    end
  end

  # @return [Hash] data for one CVE from NVD data file.
  def nvd_cve_item(cve_key)
    nvd_cve_item_hash = nvd_cve_items.find {|item| cve_key == item['cve']['CVE_data_meta']['ID']}
    return nil unless nvd_cve_item_hash
    NvdCveItem.new(nvd_cve_item_hash)
  end

  def save_cve(cve_key, ref_rec, nvd_cve_item)
    cve_rec = ref_rec.build_cve(cve_key: cve_key, year: year)
    cve_rec.assign_attributes(nvd_cve_item.attributes)
    cve_rec.affected_systems = nvd_cve_item.affected_systems.join("\n")
    cve_rec.save!
  end

  def save_references(ref_rec, nvd_cve_item)
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

  def update_cve_data
    each_missing do |cve_key, ref_rec, nvd_cve_item|
      save_cve(cve_key, ref_rec, nvd_cve_item)
      save_references(ref_rec, nvd_cve_item)
    end
  end

  def self.update_cve_data
    each_publisher do |publisher|
      publisher.update_cve_data
    end
  end
end
