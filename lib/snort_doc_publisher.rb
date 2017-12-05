class SnortDocPublisher
  def download(year)
    puts "curl https://static.nvd.nist.gov/feeds/json/cve/1.0/nvdcve-1.0-#{year}.json.gz"
  end

  def undoc_cve_refs
    @undoc_cve_refs ||= Reference.cves.left_joins(:cves)
  end

  def undoc_cve_refs_by_year
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

  def years
    undoc_cve_refs_by_year.keys
  end
end
