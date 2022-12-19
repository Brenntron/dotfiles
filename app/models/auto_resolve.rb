class AutoResolve
  include ActiveModel::Model

  #attr_accessor :address_type, :address, :resolved, :status, :rule_hits, :internal_comment, :resolution_comment, :auto_resolve_log

  attr_accessor :auto_resolve_log, :internal_comment, :resolution_comment, :status, :resolved

  ADDRESS_TYPE_IP           = 'IP'
  ADDRESS_TYPE_URI          = 'URI'
  ADDRESS_TYPE_DOMAIN       = 'DOMAIN'

  STATUS_NEW                = 'NEW'
  STATUS_MALICIOUS          = 'MALICIOUS'
  STATUS_NONMALICIOUS       = 'CLEAR'


  #entry point
  def self.process_auto_resolution(auto_args)

    umbrella_no_reply = Platform.find_by_all_names("Umbrella - No Reply")
    dispute_entry = auto_args[:dispute_entry]
    sugg_disposition = auto_args[:entry_claim]
    is_ip_address = !!(dispute_entry.hostlookup  =~ Resolv::IPv4::Regex)
    submission_type = dispute_entry.dispute.submission_type

    #######################################################################################################################################

    if submission_type == "w"
      if dispute_entry.dispute.determine_platform.present? && dispute_entry.dispute.determine_platform.downcase.include?("umbrella")
        matching_disposition = dispute_entry.is_disposition_matching?(sugg_disposition, true)
        if !matching_disposition
          if sugg_disposition == "false positive"
            if dispute_entry.determine_platform_record.present? && dispute_entry.determine_platform_record.id == umbrella_no_reply.id
              AutoResolve.auto_resolve_umbrella_false_positive(dispute_entry)
              dispute_entry.reload
            end
          end
          if sugg_disposition == "false negative"
            if dispute_entry.determine_platform_record.present? && dispute_entry.determine_platform_record.id == umbrella_no_reply.id
              if is_ip_address
                dispute_entry = AutoResolve.attempt_ai_conviction_of_ip(dispute_entry.dispute_rule_hits.pluck(:name), dispute_entry, true)
              else
                dispute_entry = AutoResolve.attempt_ai_conviction(dispute_entry.dispute_rule_hits.pluck(:name), dispute_entry, true)
              end
            else
              if is_ip_address
                dispute_entry = AutoResolve.attempt_ai_conviction_of_ip(dispute_entry.dispute_rule_hits.pluck(:name), dispute_entry)
              else
                dispute_entry = AutoResolve.attempt_ai_conviction(dispute_entry.dispute_rule_hits.pluck(:name), dispute_entry)
              end
            end
          end
        end
      else
        matching_disposition = dispute_entry.is_disposition_matching?(sugg_disposition)
        if !matching_disposition
          if sugg_disposition == "false positive"
            dispute_entry.update(status: DisputeEntry::NEW)
          end
          if sugg_disposition == "false negative"
            if is_ip_address
              dispute_entry = AutoResolve.attempt_ai_conviction_of_ip(dispute_entry.dispute_rule_hits.pluck(:name), dispute_entry)
            else
              dispute_entry = AutoResolve.attempt_ai_conviction(dispute_entry.dispute_rule_hits.pluck(:name), dispute_entry)
            end
          end
        end
      end

    end


    #######################################################################################################################################

    if submission_type == "e"
      if sugg_disposition == "false positive"
        if dispute_entry.dispute.submitter_type == "NON-CUSTOMER"
          if dispute_entry.dispute.determine_platform.present? && dispute_entry.dispute.determine_platform.downcase.include?("umbrella")
            matching_disposition = dispute_entry.is_disposition_matching?(sugg_disposition, true)
          else
            matching_disposition = dispute_entry.is_disposition_matching?(sugg_disposition)
          end

          if !matching_disposition
            if dispute_entry.determine_platform_record.present? && dispute_entry.determine_platform_record.id == umbrella_no_reply.id
              AutoResolve.auto_resolve_umbrella_false_positive(dispute_entry)
              dispute_entry.reload
            else
              if dispute_entry.dispute.submitter_type == "NON-CUSTOMER"
                AutoResolve.auto_resolve_email(dispute_entry, dispute_entry.dispute_rule_hits.pluck(:name))
                dispute_entry.reload
              end
            end
          end

        else
          ## for customer specific stuff
          dispute_entry.status = DisputeEntry::NEW
        end
      end

      if sugg_disposition == "false negative"
        if dispute_entry.dispute.submitter_type == "NON-CUSTOMER"
          if dispute_entry.dispute.determine_platform.present? && dispute_entry.dispute.determine_platform.downcase.include?("umbrella")
            matching_disposition = dispute_entry.is_disposition_matching?(sugg_disposition, true)
          else
            matching_disposition = dispute_entry.is_disposition_matching?(sugg_disposition)
          end
          if !matching_disposition
            dispute_entry.status = DisputeEntry::NEW
          end

        else
          ## for customer specific stuff
          dispute_entry.status = DisputeEntry::NEW
        end

      end

    end

    #############################################################################################################################################

    dispute_entry.save
  end

  ####NON-IP URL BASED AUTO CONVICTION#########
  #start auto resolution algorithm here
  def self.attempt_ai_conviction(rulehits, dispute_entry, skip_human_review = false)

    if auto_resolve_toggle
      results = process_uri_interrogation(rulehits, dispute_entry)
    else
      results = {}
      results[:action] = :do_not_resolve
      results[:log] = ["auto resolution is turned off or is experiencing configuration error"]
    end
    dispute_entry = process_interrogation_results(results, dispute_entry, skip_human_review)

    dispute_entry
  end

  def self.process_uri_interrogation(rulehits, dispute_entry)

    baseline_results = process_baseline_requirements(rulehits, dispute_entry)

    if baseline_results[:action] == :do_not_resolve
      return baseline_results
    end

    conviction_results = process_conviction_requirements(dispute_entry.hostlookup, baseline_results)

    return conviction_results

  end

  def self.process_baseline_requirements(rulehits, dispute_entry)
    results = {}
    results[:log ] = []
    results[:action] = nil
    results[:popularity] = nil
    begin

      umbrella_popularity_result = check_umbrella_popularity(dispute_entry.hostlookup)
      results[:log] << umbrella_popularity_result[:log]
      results[:popularity] = umbrella_popularity_result[:popularity]
      if umbrella_popularity_result[:pass]
        results[:action] = :do_not_resolve
        return results
      end

      sds_result = check_sds_allow_list(rulehits)
      results[:log] << sds_result[:log]

      if sds_result[:pass]
        results[:action] = :do_not_resolve
        return results
      end
      
      reptool_result = check_reptool_for_allow_list(dispute_entry.hostlookup)
      results[:log] << reptool_result[:log]
      if reptool_result[:pass]
        results[:action] = :do_not_resolve
        return results
      end

      results[:action] = :attempt_to_resolve
    rescue Exception => e
      Rails.logger.error(e.message)
      results[:action] = :do_not_resolve
      results[:log] << "there was an error in baseline requirements, halting auto conviction process"
      return results
    end

    results

  end

  def self.process_conviction_requirements(entry, baseline_results)
    results = {}

    results[:log] = baseline_results[:log]
    results[:action] = nil

    baseline_popularity = baseline_results[:popularity]
    begin
      virustotal_results = check_virustotal_hits(entry)

      trusted_hits = number_of_virustotal_trusted_hits(virustotal_results[:positive_scans])

      results[:log] << "vt results: #{virustotal_results[:positive_scans].join(",")}\n"
      results[:log] << "trusted vt hits: #{trusted_hits}\n"

      if trusted_hits > 0
        results[:action] = :commit_malware
        results[:resolve_category] = "1 or more trusted VT hits"
        return results
      end

      umbrella_rating_results = check_umbrella_rating(entry)
      results[:log] << umbrella_rating_results[:log]
      if umbrella_rating_results[:rating] == "malicious"
        results[:action] = :commit_malware
        results[:resolve_category] = "Malicious Umbrella Rating"
        return results
      elsif umbrella_rating_results[:rating].blank?
        results[:action] =  :do_not_resolve
        return results
      end


      if virustotal_results[:positives] > 5
        results[:action] = :commit_malware
        results[:resolve_category] = ">= 5 VT count"
        results[:log] << "total vt hits > 5, committing to reptool."
        return results
      end

      umbrella_domain_volume_results = check_umbrella_domain_volume(entry)
      results[:log] << umbrella_domain_volume_results[:log]

      if umbrella_domain_volume_results[:pass] == false
        results[:resolve_category] = "Suspicious domain volume ratio"
        results[:action] = :commit_phishing

        return results
      end

      umbrella_whois_popularity_results = check_whois_popularity_combo(entry, baseline_popularity)
      results[:log] << umbrella_whois_popularity_results[:log]
      if umbrella_whois_popularity_results[:pass] == false
        results[:action] = :commit_malware
        results[:resolve_category] = "Low popularity low age domain."
        return results
      end



      results[:action] = :do_not_resolve

    rescue Exception => e
      Rails.logger.error(e.message)
      results[:action] = :do_not_resolve
      results[:log] << "there was an error in conviction requirements, halting auto conviction process"

    end

    results
  end

  ######################END NON IP URL "WEB" #################################################################

  #######################IP BASED URL "WEB" CONVICTION #######################################################
  def self.attempt_ai_conviction_of_ip(rulehits, dispute_entry, skip_human_review = false)
    if auto_resolve_toggle
      results = process_web_ip_interrogation(rulehits, dispute_entry)
    else
      results = {}
      results[:action] = :do_not_resolve
      results[:log] = ["auto resolution is turned off or is experiencing configuration error"]
    end
    dispute_entry = process_interrogation_results(results, dispute_entry, skip_human_review, true)

    dispute_entry
  end

  def self.process_web_ip_interrogation(rulehits, dispute_entry)
    baseline_results = process_web_ip_baseline_requirements(rulehits, dispute_entry)

    if baseline_results[:action] == :do_not_resolve
      return baseline_results
    end

    conviction_results = process_web_ip_conviction_requirements(dispute_entry.hostlookup, baseline_results)

    return conviction_results
  end

  def self.process_web_ip_baseline_requirements(rulehits, dispute_entry)

    results = {}
    results[:log ] = []
    results[:action] = nil
    results[:popularity] = nil

    begin

      send_to_virustotal_for_scanning(dispute_entry.hostlookup)

      sds_result = check_sds_allow_list(rulehits)
      results[:log] << sds_result[:log]

      if sds_result[:pass]
        results[:action] = :do_not_resolve
        return results
      end

      reptool_result = check_reptool_for_allow_list(dispute_entry.hostlookup)
      results[:log] << reptool_result[:log]
      if reptool_result[:pass]
        results[:action] = :do_not_resolve
        return results
      end

      #############################

      #umbrella_popularity_result = check_umbrella_popularity_for_ip(dispute_entry.hostlookup)
      #results[:log] << umbrella_popularity_result[:log]
      #results[:popularity] = umbrella_popularity_result[:popularity]
      #if umbrella_popularity_result[:pass]
      #  results[:action] = :do_not_resolve
      #  return results
      #end

      ##################
      return results
    rescue Exception => e
      Rails.logger.error(e.message)
      results[:action] = :do_not_resolve
      results[:log] << "there was an error in baseline requirements, halting auto conviction process"
      return results
    end

  end

  def self.process_web_ip_conviction_requirements(entry, baseline_results)

    high_mark = false
    results = {}
    results[:action] = nil
    results[:log] = baseline_results[:log]
    total_domain_count = 0
    malicious_domain_count = 0

    begin
      ip_domain_info = JSON.parse(Umbrella::SecurityInfo.query_malicious_domains(entry))
      malicious_domain_count = ip_domain_info['recordInfo']['totalMaliciousDomain']
      total_domain_count = ip_domain_info['features']['rr_count']

      malicious_domain_count = 0 if malicious_domain_count.blank?
      total_domain_count = 0 if total_domain_count.blank?
    rescue Exception => e
      Rails.logger.error(e.message)
      results[:action] = :do_not_resolve
      results[:log] << "there was an error in conviction requirements, halting auto conviction process"
      return results
    end

    if total_domain_count > 100
      high_mark = true
    else
      ip_domain_info["records"].each do |record|
        popularity_for_record = check_umbrella_popularity_for_ip(record["rr"])
        if popularity_for_record > 40
          high_mark = true
        end
      end
    end

    if high_mark == true
      #vt stuff
      virustotal_results = check_virustotal_hits(entry)
      trusted_hits = number_of_virustotal_trusted_hits(virustotal_results[:positive_scans])

      if virustotal_results[:positives] >= 12 || trusted_hits > 1
        results[:action] = :commit_malware
        results[:resolve_category] = "Trusted/High Count VT hit(s)/high domain count"
        return results
      end

      #70%
      if (malicious_domain_count.to_f / total_domain_count.to_f) >= 0.7
        results[:action] = :commit_malware
        results[:resolve_category] = "70% malicious ratio/high domain count"
        return results
      else
        results[:log] << "malicious domain ratio was under 70%"
      end

      #action is do_not_resolve or
    else
      #vt stuff
      virustotal_results = check_virustotal_hits(entry)
      trusted_hits = number_of_virustotal_trusted_hits(virustotal_results[:positive_scans])

      if virustotal_results[:positives] >= 3 || trusted_hits > 0
        results[:action] = :commit_malware
        results[:resolve_category] = "Trusted/High Count VT hit(s)/low domain count"
        return results
      else
        results[:log] << "virustotal hits under thresholds"
      end

      #asn block list
      begin
        asn_blocklist = [8452,4134,45609,45899,4837,17488,7552,7713,36947,45595]
        ip_whois_info = JSON.parse(Umbrella::DomainInfo.ip_whois(entry))
        if ip_whois_info.present?
          spamhaus_code = ip_whois_info[0]['asn']
        else
          spamhaus_code = 0
        end

        if asn_blocklist.include?(spamhaus_code)
          results[:action] = :commit_malware
          results[:resolve_category] = "ASN block list/low domain count"
          return results
        else
          results[:log] << "not found in spamhaus list"
        end


      rescue Exception => e
        Rails.logger.error(e.message)
        results[:action] = :do_not_resolve
        results[:log] << "there was an error in conviction requirements, halting auto conviction process"
        return results
      end

      #20% malicious ratio
      if (malicious_domain_count.to_f / total_domain_count.to_f) >= 0.2
        results[:action] = :commit_malware
        results[:resolve_category] = "20% malicious ratio/low domain count"
        return results
      else
        results[:log] << "malicious domain ratio was under 20%"
      end
    end


    results[:action] = :do_not_resolve

    results

  end
  #######################END IP BASED URL "WEB "##############################################################

  def self.process_interrogation_results(result, dispute_entry, skip_human_review, add_additional_blocklist = false)

    action = result[:action]

    if action == :do_not_resolve || action.blank?
      if skip_human_review == true
        resolved_at = Time.now
        dispute_entry.resolution = DisputeEntry::STATUS_AUTO_RESOLVED_UNCHANGED
        dispute_entry.status = DisputeEntry::STATUS_RESOLVED
        dispute_entry.resolution_comment = Dispute::AUTORESOLVED_UNCHANGED_MESSAGE
        dispute_entry.case_closed_at = resolved_at
        dispute_entry.case_resolved_at = resolved_at
      else
        dispute_entry.status = DisputeEntry::NEW
      end

    else
      resolved_at = Time.now
      reptool_result = commit_to_reptool(action, dispute_entry)

      if reptool_result[:success]
        if add_additional_blocklist == true
          begin
            wlbl_params = {}
            wlbl_params[:urls] = [dispute_entry.hostlookup]
            wlbl_params[:trgt_list] = ["BL-heavy"]
            wlbl_params[:thrt_cat_ids] = [23]
            wlbl_params[:note] = "TE SecHub-Auto-#{dispute_entry.dispute_id}"
            Wbrs::ManualWlbl.adjust_urls_from_params(wlbl_params, username: "vrtincom")
          rescue
            dispute_entry.status = DisputeEntry::NEW
            result[:log] << "Error attempting to commit BLH to RuleAPI, setting status to NEW for manual review. (Reptool was successful)"
          end

        end
        dispute_entry.status = DisputeEntry::STATUS_RESOLVED
        dispute_entry.resolution = DisputeEntry::STATUS_AUTO_RESOLVED_FN
        dispute_entry.resolution_comment = "Talos has lowered our reputation score for the URL/Domain/Host to block access."
        dispute_entry.auto_resolve_category = result[:resolve_category]
        dispute_entry.case_closed_at = resolved_at
        dispute_entry.case_resolved_at = resolved_at
      else
        dispute_entry.status = DisputeEntry::NEW
        result[:log] << "Error attempting to commit to reptool, setting status to NEW for manual review."
        if add_additional_blocklist == true
          result[:log] << "Error in Reptool caused halt to adding blh rulehit to RuleAPI."
        end
      end

    end

    dispute_entry.auto_resolve_log = dispute_entry.auto_resolve_log.blank? ? result[:log].join("<br><br>") : dispute_entry.auto_resolve_log += result[:log].join("<br><br>")

    dispute_entry.save

    dispute_entry
  end

  def self.number_of_virustotal_trusted_hits(hits)

    total = 0
    hits.each do |hit|
      total += 1 if trusted_virustotal_hits.include?(hit)
    end

    total
  end


######################DATA CHECKS#############################

  def self.auto_resolve_toggle
    begin
      begin
        return AppConfig.auto_resolve_toggle
      rescue
        return Rails.configuration.auto_resolve.check_complaints
      end
    rescue Exception => e
      Rails.logger.error(e.message)
      return false
    end
  end

  def self.check_umbrella_popularity_for_ip(entry)
    response = Umbrella::SecurityInfo.query_info(address: entry)
    data = JSON.parse(response.body)
    return data["popularity"]
  end

  def self.check_umbrella_popularity(raw_entry)

    entry = DisputeEntry.safe_domain_of(raw_entry)

    result = {}
    result[:pass] = true
    result[:log] = ""
    result[:popularity] = nil
    begin
      response = Umbrella::SecurityInfo.query_info(address: entry)

      if response.code == 200
        data = JSON.parse(response.body)
        popularity = data["popularity"]
        if popularity.present?
          if !(popularity > 40)
            result[:pass] = false
          else
            result[:pass] = true
          end
          result[:log] = "Umbrella popularity rating: #{popularity}: result of pass: #{result[:pass]}"
          result[:popularity] = popularity
        else
          result[:pass] = true
          result[:log] = "Umbrella popularity value could not be found, sending for manual review."
        end
      else
        result[:pass] = true
        result[:log] = "Umbrella popularity api request failed. sending for manual review."
      end

      result
    rescue
      result[:rating] = nil
      result[:log] = "there was an error checking umbrella popularity"
      result
    end
  end

  def self.check_reptool_for_allow_list(entry)
    result = {}
    result[:pass] = true
    result[:log] = ""
    begin
      rep_result = RepApi::Whitelist.get_whitelist_info({:entries => [entry]})
      if rep_result[rep_result.keys.last]["status"].upcase == "ACTIVE"
        result[:pass] = true
        result[:log] = "ACTIVE entry on Reptool whitelist, manual review."
      else
        result[:pass] = false
        result[:log] = "#{rep_result[:status]} entry on Reptool whitelist, continuing."
      end
    rescue Exception => e
      if e.exception.to_s == "HTTP response 404"
        result[:pass] = false
        result[:log] = "no entry with reptool whitelist, continuing."
      else
        result[:pass] = true
        result[:log] = "unknown error with reptool, manual review."
      end
    end

    result

  end

  def self.check_sds_allow_list(rulehits)
    result = {}

    pass = rulehits.any?{|rulehit| allow_listed?(rulehit)}

    result[:pass] = pass
    if pass
      result[:log] = "allow list hits from SDS detected: #{rulehits.select{|rulehit| allow_listed?(rulehit)}.join(",")}"
    else
      result[:log] = "no sds rulehits detected against allow list"
    end

    result
  end

  def self.check_umbrella_domain_volume(entry)
    result = {}
    result[:pass] = true
    result[:log] = ""

    begin
      response = Umbrella::DomainVolume.query_domain_volume(address: DisputeEntry.safe_domain_of(entry))

      if response.code == 200
        data = JSON.parse(response.body)["queries"]

        total_queries = data.inject(0){|sum, x| sum + x }
        result[:log] = "domain volume is zero, moving on."
        if total_queries == 0
          return result
        end
        result[:log] = "no suspicious data points found."
        data.each do |data_point|
          if data_point.to_i == 0
            next
          end
          data_point_factor = (data_point.to_f / total_queries.to_f)
          if data_point_factor > 0.1
            result[:pass] = false
            result[:log] = "suspicious data point found: #{data_point.to_f.to_s} / #{total_queries.to_f.to_s} = #{data_point_factor.to_s}"
            return result
          end

        end

      elsif response.code >= 300
        result[:pass] = true
        result[:log] = "bad http code from umbrella domain volume check, manual review needed."
        return result
      end

      result
    rescue
      result[:pass] = true
      result[:log] = "unknown error with domain volume check, manual review needed."
      return result
    end
  end

  def self.check_virustotal_hits(entry)
    vt_results = Virustotal::Scan.scan_hashes(address: entry)

    result = {}
    result[:positives] = 0
    result[:positive_scans] = []
    result[:total_scans] = vt_results["scans"].keys.size rescue nil
    result[:permalink] = vt_results["permalink"] rescue nil 

    if vt_results && vt_results['scans']
      result[:positives] = vt_results["positives"]
      if result[:positives] > 0
        result[:positive_scans] = vt_results["scans"].keys.select {|key| vt_results["scans"][key]["detected"] == true}
      end
    end

    result
  end

  def self.check_umbrella_rating(entry)

    result = {}
    result[:rating] = nil
    result[:log] = ""
    response = Umbrella::Scan.scan_result(address: DisputeEntry.safe_domain_of(entry))

    if response.code == 200
      data = JSON.parse(response.body)
      result[:rating] = data[data.keys.first]["status"] == -1 ? "malicious" : "trusted"
      result[:log] = "umbrella rating returned #{data[data.keys.first]["status"]}"
    else
      result[:rating] = nil
      result[:log] = "umbrella rating failed for unknown reason. halting for manual review."
    end

    result
  end

  def self.check_domain_life(entry)

    result = {}
    result[:age] = nil
    result[:created] = nil
    result[:log] = ""
    result[:pass] = true
    response = Umbrella::DomainInfo.domain_whois(domain: DisputeEntry.safe_domain_of(entry))

    if response.code == 200
      data = JSON.parse(response.body)
      result[:created] = data["created"]
      result[:age] = (Date.today - Date.parse(data["created"])) rescue nil

      result[:log] = "umbrella whois returned #{data["created"]}"
      if result[:age].blank?
        result[:pass] = true
        result[:log] += " Created field came back blank, halting for manual review"
      else
        result[:pass] = false
      end
    else
      result[:pass] = true
      result[:log] = "umbrella domain whois failed for unknown reason. halting for manual review."
    end

    result

  end

  def self.check_whois_popularity_combo(entry, popularity)

    result = {}
    result[:pass] = true
    result[:log] = ""

    domain_life_results = check_domain_life(entry)
    result[:log] += domain_life_results[:log]
    if domain_life_results[:pass] == true
      return result
    end

    if domain_life_results[:age] < 90.0 && popularity == 0
      result[:pass] = false
      result[:log] += " age is less than 90 days and popularity is 0, should blocklist."
    else
      result[:pass] = true
      result[:log] += " age is greater or equal to 90 days and popularity is greater than 0, manual review"
    end
    result[:log] += " age: #{domain_life_results[:age]} | popularity: #{popularity}"

    result
  end

  def self.send_to_virustotal_for_scanning(entry)
    Virustotal::Scan.send_to_scan(entry)
  end

  ###############################################################################################################


  def self.commit_to_reptool(action, dispute_entry)

    result = {}
    result[:success] = false

    author = "reptooluser"

    classification = nil

    case action
      when :commit_malware
        classification = "malware"
      when :commit_phishing
        classification = "phishing"
    end

    comment = "TE SecHub-Auto-#{dispute_entry.dispute_id}"
    
    begin
      if classification.present?

        RepApi::Blacklist.add_from_hosts(hostnames: [ dispute_entry.hostlookup ], classifications: [ classification ], author: author, comment: comment, force: true)
        result[:success] = true
      end

    rescue Exception => e

      Rails.logger.error(e.message)
      result[:success] = false
    end

    result
  end

  def self.allow_listed?(rule_hit)
    %w{tuse a500 vsvd suwl wlw wlm wlh deli ciwl beaker_drl}.include?(rule_hit)
  end

  def self.trusted_virustotal_hits
    %w{Kaspersky Sophos Avira Google\ Safebrowsing BitDefender}
  end

  ########################################
  #for custom email based auto resolve
  ########################################

  def self.publish_to_rep_api(dispute = nil, uri, author: 'reptooluser')
    if dispute.present?
      comment = "TE SecHub-Auto-#{dispute_id}"
    else
      comment = "TE SecHub-Auto"
    end

    RepApi::Blacklist.add_from_hosts(hostnames: [ uri ],
                                     classifications: [ 'malware' ],
                                     author: author,
                                     comment: comment,
                                     force: true)
  end

  def self.bad_email_mnem?(rule_hit)

    if rule_hit.downcase.strip.ends_with?("bl")
      return true
    end

    if rule_hit.downcase.strip.starts_with?("dh")
      return true
    end

    if rule_hit.downcase.strip.starts_with?("ia")
      return true
    end

  end

  def self.build_resolution_message(rule_hits)
    #look for ia* and dh* rulehits (DhL DhM DhH) (IaL IaM IaH)
    has_ia = rule_hits.select{|rulehit| rulehit.downcase.strip.starts_with?("ia")}.present?
    has_dh = rule_hits.select{|rulehit| rulehit.downcase.strip.starts_with?("dh")}.present?

    #look for *bl rulehits (Sbl, Pbl, Cbl)

    has_bl = rule_hits.select{|rulehit| rulehit.downcase.strip.ends_with?("bl")}.present?

    #construct message
    message = ""

    if has_ia || has_dh
      message += "Our worldwide sensor network indicates that spam originated from your IP."

      if has_dh
        message += " In addition, our sensors indicate server access attempts from this IP to mail servers within our Sensor Network. This behavior is indicative of email directory harvesting attempts and also results in reputation impact to the IP. Directory harvest detection fires when you are sending to invalid email addresses."
      end
      message += " It is possible that your network or a system in your network may be compromised by a trojan spam virus, or perhaps there is an open port 25 through which a spammer may be gaining access and sending out spam. The last possibility is that one of your users is sending spam through the IP. We suggest checking these possibilities to help isolate the root cause of the spam and mail server access attempts originating from your IP. In general, once all issues have been addressed (fixed), reputation recovery can take anywhere from a few hours to just over one week to improve, depending on the specifics of the situation, and how much email volume the IP sends. Complaint ratios determine the amount of risk for receiving mail from an IP, so logically, reputation improves as the ratio of legitimate mails increases with respect to the number of complaints. Speeding up the process is not really possible. Talos Intelligence Reputation is an automated system over which we have very little manual influence."
    end

    if has_bl
      message += " Your IP has a poor Talos Intelligence Reputation due to currently being listed on Spamhaus (http://www.spamhaus.org/) Review the status and reason(s) by visiting https://www.spamhaus.org/lookup/and entering your IP. Please contact Spamhaus directly to resolve this listing issue. Once delisted, the Talos Intelligence Reputation for the IP should improve within 24 hours."
    end

    message
  end

  def self.auto_resolve_email(dispute_entry, rule_hits)
    auto_resolve_log = "\n-----------non customer email ip check--------------\n"
    bad_mnems = rule_hits.select{|rule_hit| bad_email_mnem?(rule_hit)}
    if bad_mnems.any?
      auto_resolve_log += "bad email hits were found:\n"
      auto_resolve_log += "#{bad_mnems.inspect.to_s}\n"
      dispute_entry.resolution = DisputeEntry::STATUS_AUTO_RESOLVED_UNCHANGED
      dispute_entry.status = DisputeEntry::STATUS_RESOLVED
      dispute_entry.case_closed_at = Time.now
      dispute_entry.case_resolved_at = Time.now
      dispute_entry.auto_resolve_log += auto_resolve_log
      dispute_entry.resolution_comment = build_resolution_message(rule_hits)
      dispute_entry.save

      return true

    end

    return false

  end

  ############################LEGACY SUPPORT SECTION###################################
  #
  # until such time they can be refactored, this is for supporting code that (should not) call methods
  # from AutoResolve as part of their non-auto resolution related functionality

  def call_umbrella(address: self.address)
    response = Umbrella::Scan.scan_result(address: address)
    case
    when 300 <= response.code
      Rails.logger.error("Umbrella http response #{response.code}")
      return nil
    when 200 != response.code
      Rails.logger.warn("Umbrella http response #{response.code}")
    end
    JSON.parse(response.body)
  end

  #
  # ####################################################################################



  def self.auto_resolve_umbrella_false_positive(dispute_entry)
    dispute_entry.resolution = DisputeEntry::STATUS_AUTO_RESOLVED_UNCHANGED
    dispute_entry.status = DisputeEntry::STATUS_RESOLVED
    dispute_entry.case_closed_at = Time.now
    dispute_entry.case_resolved_at = Time.now
    dispute_entry.resolution_comment = "The following ticket queue is for false negative requests only. If you would like to dispute the reputation of an Untrusted verdict, please open a Web Reputation ticket."
    dispute_entry.save

  end
end
