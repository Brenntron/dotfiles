class TalosEscalationAnalysis
  #TEA in TE parlance
  #This will try to replicate as closely as possible the same TEA data that the TE team uses

  #sources:
  # Virustotal
  # Umbrella
  # Reptool
  # Beaker and/or SDS

  def self.get_data_as_hash(entry, json=false, admin=false)

    tea_data = {}
    tea_data[:entry] = {}
    tea_data[:web_reputation] = {}            #sds and/or beaker
    tea_data[:security_intelligence] = {}     #reptool
    tea_data[:virustotal] = {}                #virustotal
    tea_data[:umbrella] = {}                  #umbrella


    tea_data[:entry][:url] = entry
    tea_data[:entry][:ip_address] = Resolv.getaddress('1234computer.com') rescue nil

    ###WEB REP
    begin
      tea_data[:web_reputation] = get_web_rep_data(entry)
    rescue Exception => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
      if admin==false
        tea_data[:web_reputation] = {}
      else
        tea_data[:web_reputation] = e.message + " " + e.backtrace.join("\n")
      end
    end

    ###REPTOOL
    begin
      tea_data[:security_intelligence] = get_reptool_data(entry)
    rescue Exception => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
      if admin==false
        tea_data[:security_intelligence] = {}
      else
        tea_data[:security_intelligence] = e.message + " " + e.backtrace.join("\n")
      end
    end

    ###VIRUSTOTAL
    begin
      tea_data[:virustotal] = get_virustotal_data(entry)
    rescue Exception => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
      if admin==false
        tea_data[:virustotal] = {}
      else
        tea_data[:virustotal] = e.message + " " + e.backtrace.join("\n")
      end
    end

    ###UMBRELLA
    begin
      tea_data[:umbrella] = get_umbrella_data(entry)
    rescue Exception => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
      if admin==false
        tea_data[:umbrella] = {}
      else
        tea_data[:umbrella] = e.message + " " + e.backtrace.join("\n")
      end
    end

    if json == true
      tea_data.as_json
    else
      tea_data
    end

  end

  def self.get_web_rep_data(entry)

    results = {}
    results[:rules] = nil
    results[:score] = nil
    results[:category] = nil
    results[:threat_level] = nil
    results[:xena] = nil

    wbrs_api_response = Sbrs::Base.remote_call_sds_v3(entry, "wbrs")

    score = wbrs_api_response['wbrs']['score']
    wbrs_rulehits = Sbrs::ManualSbrs.get_rule_names_from_rulehits(wbrs_api_response) rescue nil

    rulehits = []
    wbrs_rulehits.each do |rule_hit|
      rulehits << rule_hit.strip
    end

    results[:score] = score
    if rulehits.present?
      results[:rules] = rulehits
    end

    current_cat = DisputeEntry.get_primary_category(entry)
    if current_cat.present? && current_cat != {}
      results[:category] = current_cat
    end

    xena_entry = DisputeEntry.safe_domain_of(entry)
    #this isn't fully implemented yet, requires api keys to complete, per https://jira.talos.cisco.com/browse/TPHU-1831
    # will create an additional follow up ticket to square this away.
    results[:xena] = Xena::GuardRails.is_allow_listed?(xena_entry) rescue nil

    results[:threat_level] = SbApi.wbrs_to_new_threat_level(results[:score]) rescue nil

    return results
  end

  def self.get_reptool_data(entry)
    results = {}
    results[:bl_classification] = nil
    results[:bl_status] = nil
    results[:bl_comment] = nil
    results[:wl_status] = nil

    block_list_info = RepApi::Blacklist.where(:entries => [entry]).first rescue nil

    if block_list_info.present?
      results[:bl_classification] = block_list_info.classifications
      results[:bl_status] = block_list_info.status
      results[:bl_comment] = block_list_info.metadata["VRT"]["comment"] rescue nil
    end

    allow_list_info = RepApi::Whitelist.get_whitelist_info({:entries => [entry]}) rescue {}
    results[:wl_status] = allow_list_info[allow_list_info.keys.last]["status"] rescue nil

    results

  end

  def self.get_virustotal_data(entry)
    results = {}
    results[:url_detection] = nil
    results[:trusted_detection] = nil
    results[:detected_urls] = nil
    results[:permalink] = nil

    by_domain_result = Virustotal::GetVirustotal.by_host_domain(entry) rescue nil

    vt_scans = AutoResolve.check_virustotal_hits(entry) rescue nil
    if vt_scans.present?
      results[:url_detection] = vt_scans[:positives].to_s + "/" + vt_scans[:total_scans].to_s rescue nil
      results[:trusted_detection] = AutoResolve.number_of_virustotal_trusted_hits(vt_scans[:positive_scans]).to_s + "/5"
      results[:permalink] = vt_scans[:permalink] rescue nil
    end

    if by_domain_result.present?
      results[:detected_urls] = by_domain_result["detected_urls"].size rescue nil
    end

    results

  end

  def self.get_umbrella_data(entry)

    results = {}
    results[:rating] = nil
    results[:category] = nil
    results[:popularity] = nil
    results[:domain_volume] = nil
    results[:registrar] = nil
    results[:organization] = nil
    results[:email] = nil
    results[:created] = nil

    safe_entry = DisputeEntry.safe_domain_of(entry)

    domain_volume = Umbrella::DomainVolume.query_domain_volume(address: safe_entry) rescue {}
    rep_info = Umbrella::Scan.scan_result(address: safe_entry) rescue {}
    security_info = Umbrella::SecurityInfo.query_info(address: safe_entry) rescue {}

    results[:popularity] = JSON.parse(security_info.body)["popularity"] rescue nil

    ##################
    if domain_volume.code == 200
      results[:domain_volume] = "NORMAL"
      data = JSON.parse(domain_volume.body)["queries"]

      total_queries = data.inject(0){|sum, x| sum + x }

      if total_queries == 0
        results[:domain_volume] = "ZERO DOMAIN VOLUME"
      else

        data.each do |data_point|
          if data_point.to_i == 0
            next
          end
          data_point_factor = (data_point.to_f / total_queries.to_f)
          if data_point_factor > 0.1
            results[:domain_volume] = "SUSPICIOUS"
          end

        end
      end

    else
      results[:domain_volume] = nil
    end
    #########################


    if rep_info.code == 200
      data = JSON.parse(rep_info.body)
      results[:rating] = data[data.keys.first]["status"] == -1 ? "malicious" : "trusted"
    else
      results[:rating] = nil
    end
    #########################

    timeline_result = JSON.parse(Umbrella::Timeline.query_timeline(address: safe_entry).body) rescue nil
    if timeline_result.present?
      results[:category] = timeline_result.first["categories"]
    end

    #########################

    whois_result = JSON.parse(Umbrella::Whois.query_whois(address: safe_entry).body) rescue nil
    if whois_result.present?
      results[:registrar] = whois_result["registrarName"] rescue nil
      results[:organization] = whois_result["registrantOrganization"] rescue nil
      results[:email] = whois_result["emails"] rescue nil
      results[:created] = whois_result["created"] rescue nil
    end

    results
  end

end
