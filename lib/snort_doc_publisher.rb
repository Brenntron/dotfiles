class SnortDocPublisher
  attr_reader :year, :nvd_cve_item

  def self.undoc_cve_refs
    @undoc_cve_refs ||= Reference.cves.left_joins(:cve)
  end

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

  def self.years
    undoc_cve_refs_by_year.keys
  end

  def initialize(year)
    @year = year
  end

  def filename
    "nvdcve-1.0-#{@year}.json"
  end

  def filepath
    "lib/data/nvd/#{filename}"
  end

  def download
    puts "curl https://static.nvd.nist.gov/feeds/json/cve/1.0/#{filename}.gz > #{filepath}.gz"
  end

  def nvd_cve_items
    @nvd_cve_items ||= File.open(filepath, 'r') do |file|
      filedata = JSON.parse(file.read)
      filedata['CVE_Items']
    end
  end

  def nvd_cve_item(cve_key)
    nvd_cve_item_hash = nvd_cve_items.find {|item| cve_key == item['cve']['CVE_data_meta']['ID']}
    return nil unless nvd_cve_item_hash
    NvdCveItem.new(nvd_cve_item_hash)
  end
end
