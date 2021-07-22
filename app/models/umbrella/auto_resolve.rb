class Umbrella::AutoResolve
  include ActiveModel::Model

  attr_accessor :auto_resolve_log, :internal_comment, :resolution_comment, :status, :resolved

  ADDRESS_TYPE_IP           = 'IP'
  ADDRESS_TYPE_URI          = 'URI'
  ADDRESS_TYPE_DOMAIN       = 'DOMAIN'

  STATUS_NEW                = 'NEW'
  STATUS_MALICIOUS          = 'MALICIOUS'
  STATUS_NONMALICIOUS       = 'CLEAR'


  # had to backpedal on using this at the very last minute, but keeping this in existence in case the target moves
  # in this direction again soon.

  def self.attempt_ai_conviction(rulehits, dispute_entry)

    if auto_resolve_toggle
      results = process_uri_interrogation(rulehits, dispute_entry)
    else
      results = {}
      results[:action] = :do_not_resolve
      results[:log] = ["auto resolution is turned off or is experiencing configuration error"]
    end

    dispute_entry = process_interrogation_result(results, dispute_entry)

    dispute_entry
  end

  def self.process_uri_interrogation(rulehits, dispute_entry)
    baseline_results = process_baseline_requirements(rulehits, dispute_entry)

    return baseline_results

  end


  def self.process_baseline_requirements(rulehits, dispute_entry)

    results = {}
    results[:log ] = []
    results[:action] = nil
    begin

      umbrella_popularity_result = check_umbrella_popularity(dispute_entry.hostlookup)
      results[:log] << umbrella_popularity_result[:log]
      if umbrella_popularity_result[:pass]
        results[:action] = :do_not_resolve
        return results
      end

      allow_list_result = check_allow_lists(dispute_entry.hostlookup, rulehits)
      results[:log] << allow_list_result[:log]

      if allow_list_result[:pass]
        results[:action] = :do_not_resolve
        return results
      end

      volume_result = check_umbrella_domain_volume(dispute_entry.hostlookup)
      results[:log] << volume_result[:log]
      if volume_result[:pass]
        results[:action] = :do_not_resolve
        return results
      end

      results[:action] = :commit_malware

      results
    rescue Exception => e
      Rails.logger.error(e.message)
      results[:action] = :do_not_resolve
      results[:log] << "there was an error in baseline requirements, halting auto conviction process"
      results
    end


  end


  def self.process_interrogation_result(result, dispute_entry)

    action = result[:action]

    if action == :do_not_resolve || action.blank?
      dispute_entry.status = DisputeEntry::NEW
    else

      resolved_at = Time.now
      reptool_result = commit_to_reptool(action, dispute_entry)
      if reptool_result[:success]
        dispute_entry.status = DisputeEntry::STATUS_RESOLVED
        dispute_entry.resolution = DisputeEntry::STATUS_RESOLVED_FIXED_FN
        dispute_entry.resolution_comment = "Talos has lowered our reputation score for the URL/Domain/Host to block access."
        dispute_entry.case_closed_at = resolved_at
        dispute_entry.case_resolved_at = resolved_at
      else
        dispute_entry.status = DisputeEntry::NEW
        result[:log] << "Error attempting to commit to reptool, setting status to NEW for manual review."
      end
    end

    dispute_entry.auto_resolve_log = dispute_entry.auto_resolve_log.blank? ? result[:log].join("<br><br>") : dispute_entry.auto_resolve_log += result[:log].join("<br><br>")

    dispute_entry.save

    dispute_entry

  end


  def self.check_umbrella_domain_volume(entry)
    result = {}
    result[:pass] = true
    result[:log] = ""

    begin
      response = Umbrella::DomainVolume.query_domain_volume(address: entry)

      if response.code == 200
        data = JSON.parse(response.body)["queries"]


        ###### check each day ##########
        #
        high_day_flag = false
        data.each_slice(24).each do |data_day|
          if data_day.size == 24
            sum = data_day.inject(0){|sum, x| sum + x}
            if sum > 100
              high_day_flag = true
            end
          end
        end

        ###### check all days ######
        high_month_flag = false

        sum = data.inject(0){|sum, x| sum + x}

        if sum > 1000
          high_month_flag = true
        end


        ######  determine high volume pass/fail ##############
        if high_month_flag == true && high_day_flag == true
          result[:pass] = true
          result[:log] = "found high volume in day and month, send to TE for manual review"
        else
          result[:pass] = false
          result[:log] = "found no signs of high volume, proceed to auto resolve"
        end

        return result


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




  def self.check_umbrella_popularity(raw_entry)

    entry = DisputeEntry.safe_domain_of(raw_entry)

    result = {}
    result[:pass] = true
    result[:log] = ""

    begin
      response = Umbrella::SecurityInfo.query_info(address: entry)

      if response.code == 200
        data = JSON.parse(response.body)
        popularity = data["popularity"]
        if popularity.present?
          if popularity > 40
            result[:pass] = true
          else
            result[:pass] = false
          end
          result[:log] = "Umbrella popularity rating: #{popularity}: result of pass: #{result[:pass]}"
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


  def self.check_allow_lists(raw_entry, rulehits)

    result = {}
    result[:pass] = false
    result[:log] = []

    sds_result = check_sds_allow_list(rulehits)

    reptool_result = check_reptool_for_allow_list(raw_entry)

    xena_result = check_xena_for_allow_list(raw_entry)

    result[:log] << sds_result[:log]
    result[:log] << reptool_result[:log]
    result[:log] << xena_result[:log]

    if [sds_result, reptool_result, xena_result].any?{|result| result[:pass] == true}
      result[:pass] = true
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

  def self.check_reptool_for_allow_list(entry)
    result = {}
    result[:pass] = true
    result[:log] = ""
    begin
      rep_result = RepApi::Whitelist.get_whitelist_info({:entries => [entry]})
      if rep_result[rep_result.keys.last]["status"] == "ACTIVE"
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

  def self.check_xena_for_allow_list(raw_entry)
    result = {}
    result[:pass] = true
    result[:log] = ""

    begin
      entry = DisputeEntry.safe_domain_of(raw_entry)
      result[:pass] = Xena::GuardRails.is_allow_listed?(entry)
      if result[:pass] == true
        result[:log] = "allow listed on xena, manual review"
      else
        result[:log] = "no allow list entry on xena, continuing"
      end
    rescue Exception => e
      result[:pass] = true
      result[:log] = "unkown error with xena, manual review"
    end

    result
  end


  def self.auto_resolve_toggle
    begin
      Rails.configuration.auto_resolve.check_complaints
    rescue Exception => e
      Rails.logger.error(e.message)
      false
    end
  end

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
        RepApi::Blacklist.add_from_hosts(hostnames: [ dispute_entry.hostlookup ],
                                         classifications: [ classification ],
                                         author: author,
                                         comment: comment)

        result[:success] = true
      end

    rescue Exception => e
      Rails.logger.error(e.message)
      result[:success] = false
    end

    result
  end

end