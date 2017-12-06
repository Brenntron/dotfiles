class NvdCveItem
  def initialize(nvd_cve_item_hash)
    @nvd_cve_item_hash = nvd_cve_item_hash
  end

  def description
    summary_langs = @nvd_cve_item_hash['cve']['description']['description_data']
    summary_en = summary_langs.find{ |desc_data| 'en' == desc_data['lang'] }
    summary_en['value']
  end

  def cvss_base_metric
    @cvss_base_metric ||=
        case
          when @nvd_cve_item_hash['impact']['baseMetricV3']
            @nvd_cve_item_hash['impact']['baseMetricV3']
          when @nvd_cve_item_hash['impact']['baseMetricV2']
            @nvd_cve_item_hash['impact']['baseMetricV2']
          else
            {}
        end
  end

  def cvss_subsection
    @cvss_subsection ||=
        case
          when @nvd_cve_item_hash['impact']['baseMetricV3']
            @nvd_cve_item_hash['impact']['baseMetricV3']['cvssV3']
          when @nvd_cve_item_hash['impact']['baseMetricV2']
            @nvd_cve_item_hash['impact']['baseMetricV2']['cvssV2']
          else
            {}
        end
  end

  def base_score
    cvss_subsection['baseScore']
  end

  def impact_score
    cvss_base_metric['impactScore']
  end

  def exploit_score
    cvss_base_metric['exploitabilityScore']
  end

  def confidentiality_impact
    cvss_subsection['confidentialityImpact']
  end

  def integrity_impact
    cvss_subsection['integrityImpact']
  end

  def availability_impact
    cvss_subsection['availabilityImpact']
  end

  def affected_data
    @nvd_cve_item_hash['cve']['affects']['vendor']['vendor_data']
  end

  def each_affected_vendor_datum
    affected_data.each do |vendor_datum|
      yield vendor_datum['vendor_name'], vendor_datum['product']['product_data']
    end
  end

  def each_affected_product_datum
    each_affected_vendor_datum do |vendor, product_data|
      product_data.each do |product_datum|
        yield vendor, product_datum['product_name'], product_datum['version']['version_data']
      end
    end
  end

  def each_affected_system
    each_affected_product_datum do |vendor, product, version_data|
      version_data.each do |version_datum|
        yield vendor, product, version_datum['version_value']
      end
    end
  end

  def affected_systems
    result = []
    each_affected_system do |vendor, product, version|
      result << "#{vendor} #{product} #{version}"
    end
    result
  end
end
