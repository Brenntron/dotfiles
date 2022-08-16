module Escalations::Sdr::DisputesHelper
  def dispute_age(assigned_at)
    return '' unless assigned_at
    age = assigned_at - DateTime.now
    age = age.abs # lazy
    mm, ss = age.divmod(60)
    hh, mm = mm.divmod(60)
    dd, hh = hh.divmod(24)
    if dd > 0
      "%dd %dh" % [dd, hh]
    elsif hh > 0
      "%dh %dm" % [hh, mm]
    elsif hh == 0
      "<1 hr"
    end
  end

  def extract_details(description)
    return [] if description.nil?
    extracted_details = description.split(".\r")[0]
    extracted_details = extracted_details.split(',')
  end

  def humanize_beaker_info(beaker_info)
    beaker_data = JSON.parse(beaker_info).with_indifferent_access
    return beaker_data.to_json if beaker_data['status'] == 'failed' || beaker_data.dig('response', 'data').empty?

    entry = beaker_data.dig('response', 'data').keys.first
    data = beaker_data.dig('response', 'data', entry)
    threat_categories = data['threat_cat_id'].map { |cat_id| CloudIntel::ThreatCatMap.threat_category_by_id(cat_id) }.join(', ')
    new_data = data.except('threat_level_id', 'query_ts', 'threat_cat_id').merge(
      {
        threat_level: CloudIntel::ThreatLevelMap.get_threat_level_mnemonic(data['threat_level_id']),
        threat_category: threat_categories.empty? ? 'unknown' : threat_categories,
        query_time: Time.at(data['query_ts'] / 1000).strftime("%Y-%m-%d %H:%M:%S")
      }
    )
    beaker_data['response']['data'][entry] = new_data
    beaker_data.to_json
  end
end
