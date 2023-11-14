require 'socket'

class DisputeEntry < ApplicationRecord
  attr_writer :wbrs_xlist

  attr_accessor :running_verdict

  has_paper_trail on: [:update], ignore: [:updated_at, :entry_type]
  has_many :telemetry_histories
  belongs_to :dispute, touch: true
  belongs_to :user, optional: true
  has_many :dispute_rule_hits
  has_one  :dispute_entry_preload
  belongs_to :product_platform, :class_name => "Platform", :foreign_key => "platform_id", optional: true
  RESOLVED = "RESOLVED"
  NEW = "NEW"
  ASSIGNED = "ASSIGNED"
  CLOSED = "CLOSED"

  STATUS_RESEARCHING = "RESEARCHING"
  STATUS_ESCALATED = "ESCALATED"
  STATUS_CUSTOMER_PENDING = "CUSTOMER_PENDING"
  STATUS_CUSTOMER_UPDATE = "CUSTOMER_UPDATE"
  STATUS_ON_HOLD = "ON_HOLD"
  STATUS_RESOLVED = "RESOLVED_CLOSED"
  STATUS_REOPENED = "RE-OPENED"

  STATUS_RESOLVED_FIXED_FP = "FIXED_FP"
  STATUS_RESOLVED_FIXED_FN = "FIXED_FN"
  STATUS_RESOLVED_UNCHANGED = "UNCHANGED"
  STATUS_RESOLVED_INVALID = "INVALID"
  STATUS_RESOLVED_TEST = "TEST_TRAINING"
  STATUS_RESOLVED_OTHER = "OTHER"
  STATUS_RESOLVED_QUICK_BULK = "QUICK_BULK" #tickets created and closed using the quick bulk entry form.

  STATUS_RESOLVED_DUPLICATE = "DUPLICATE"

  STATUS_AUTO_RESOLVED_FP = "AP - FP"
  STATUS_AUTO_RESOLVED_FN = "AP - FN"
  STATUS_AUTO_RESOLVED_MATCH = "AP - Match"
  STATUS_AUTO_RESOLVED_DUPLICATE = "AP - Duplicate"
  STATUS_AUTO_RESOLVED_UNCHANGED = "AP - Unchanged"

  delegate :cvs_username, to: :dispute, allow_nil: true


  scope :open_entries, -> { where(status: NEW) }
  scope :assigned_entries, -> { where(status: ASSIGNED) }
  scope :closed_entries, -> { where(status: RESOLVED) }
  scope :in_progress_entries, -> { where.not(status: [ NEW, RESOLVED ]) }
  scope :my_team, ->(user) { joins(:dispute).where(disputes: {user_id: user.my_team}) }

  scope :resolved_date, -> (date_from_iso, date_to_iso) {
    date_from = Date.iso8601(date_from_iso)
    date_to = Date.iso8601(date_to_iso) + 1
    where(case_resolved_at: (date_from..date_to))
  }

  validates_length_of :resolution_comment, maximum: 2000, allow_blank: true

  after_initialize do |dispute_entry|
    is_ip_address = !!(dispute_entry.uri =~ Resolv::IPv4::Regex)

    if is_ip_address && dispute_entry.entry_type != "URI/DOMAIN"
      dispute_entry.ip_address = dispute_entry.uri
      dispute_entry.uri = nil
      dispute_entry.entry_type = "IP"
      dispute_entry.hostname = nil
    end

  end

  def self.create_dispute_entry(dispute, ip_url, status = NEW)
    begin
      ip_url = ip_url.gsub("\u200B", "")
      new_dispute_entry = DisputeEntry.new
      new_dispute_entry.dispute_id = dispute.id
      new_dispute_entry.status = status

      sbrs_api_rulehits = nil

      th_packet = {}
      if is_ip?(ip_url)

        wbrs_api_response = Sbrs::Base.remote_call_sds_v3(ip_url, "wbrs")
        sbrs_api_response = Sbrs::ManualSbrs.call_sbrs('ip' => ip_url)
        sbrs_api_rulehits = CloudIntel::Reputation.mnemonics_ip(ip_url)



        new_dispute_entry.ip_address = ip_url
        new_dispute_entry.entry_type = "IP"
        new_dispute_entry.primary_category = get_primary_category(ip_url)


        # Populate WBRS/SBRS Scores

        if wbrs_api_response != nil && wbrs_api_response['wbrs'].present? && wbrs_api_response['wbrs']['score'] != 'noscore'
          new_dispute_entry.wbrs_score = wbrs_api_response['wbrs']['score']
        else
          new_dispute_entry.wbrs_score = nil
        end


        if sbrs_api_response != nil && sbrs_api_response['sbrs'].present? && sbrs_api_response['sbrs'].present? && sbrs_api_response['sbrs']['score'] != 'noscore'
          new_dispute_entry.sbrs_score = sbrs_api_response['sbrs']['score']
        else
          new_dispute_entry.sbrs_score = nil
        end

      else

        resolved_ip = Resolv.getaddress(DisputeEntry.domain_of(ip_url)) rescue nil
        if resolved_ip.present?
          new_dispute_entry.web_ips = [resolved_ip]
        end



        wbrs_api_response = Sbrs::Base.remote_call_sds_v3(ip_url, "wbrs")
        sbrs_api_response = Sbrs::ManualSbrs.call_sbrs({'url' => ip_url}, type: 'wbrs')

        url_parts = Complaint.parse_url(ip_url)
        new_dispute_entry.uri = ip_url
        new_dispute_entry.entry_type = "URI/DOMAIN"
        new_dispute_entry.subdomain = url_parts[:subdomain]
        new_dispute_entry.domain = url_parts[:domain]
        new_dispute_entry.path = url_parts[:path]

        new_dispute_entry.primary_category = get_primary_category(ip_url)

        # Populate WBRS/SBRS Scores

        if wbrs_api_response != nil && wbrs_api_response['wbrs'].present? && wbrs_api_response['wbrs']['score'] != 'noscore'
          new_dispute_entry.wbrs_score = wbrs_api_response['wbrs']['score']
        else
          new_dispute_entry.wbrs_score = nil
        end

        if sbrs_api_response != nil && sbrs_api_response['sbrs'].present? && sbrs_api_response['sbrs'].present? && sbrs_api_response['sbrs']['score'] != 'noscore'
          new_dispute_entry.sbrs_score = sbrs_api_response['sbrs']['score']
        else
          new_dispute_entry.sbrs_score = nil
        end

        if new_dispute_entry.uri.present? && new_dispute_entry.web_ips.present?
          web_ips_formatted = new_dispute_entry.web_ips.gsub("[", "").gsub("]", "").gsub("\"", "").split(", ")

          extra_wbrs_stuff = Sbrs::Base.combo_call_sds_v3(new_dispute_entry.uri, web_ips_formatted)
          extra_wbrs_stuff_rulehits = Sbrs::ManualSbrs.get_rule_names_from_rulehits(extra_wbrs_stuff) rescue []

          if extra_wbrs_stuff.present?
            new_dispute_entry.score = extra_wbrs_stuff["wbrs"]["score"]
            th_packet[:multi_ip_score] = new_dispute_entry.score
            threat_cats = extra_wbrs_stuff["threat_cats"]

            threat_cat_names = []
            if threat_cats.present?
              threat_cat_info = DisputeEntry.threat_cats_from_ids(threat_cats)
              threat_cat_info.each do |name|
                threat_cat_names << name[:name]
              end
              new_dispute_entry.multi_wbrs_threat_category = threat_cat_names
              th_packet[:rule_hits] = threat_cat_names.to_json
            end
          end
          new_dispute_entry.save
          multi_ip_rulehits = []
          extra_wbrs_stuff_rulehits.each do |rule_hit|
            new_rule_hit = DisputeRuleHit.new
            new_rule_hit.dispute_entry_id = new_dispute_entry.id
            new_rule_hit.name = rule_hit.strip
            new_rule_hit.rule_type = "WBRS"
            new_rule_hit.is_multi_ip_rulehit = true
            new_rule_hit.save
            multi_ip_rulehits << {:name => new_rule_hit.name, :rule_type => new_rule_hit.rule_type}
          end
          th_packet[:multi_rule_hits] = multi_ip_rulehits.to_json
        end

      end

      th_packet[:wbrs_score] = new_dispute_entry.wbrs_score rescue nil
      th_packet[:sbrs_score] = new_dispute_entry.sbrs_score rescue nil

      new_dispute_entry.save!
      ::Preloader::Base.fetch_all_api_data(ip_url, new_dispute_entry.id)
      # Create Dispute Entry RuleHits

      rule_hits_snapshot = []

      wbrs_rule_hits = Sbrs::ManualSbrs.get_rule_names_from_rulehits(wbrs_api_response)

      if wbrs_rule_hits.present?
        wbrs_rule_hits.each do |rule_hit|
          DisputeRuleHit.create(rule_type:'WBRS', name: rule_hit, dispute_entry_id: new_dispute_entry.id)
          rule_hits_snapshot << {:name => rule_hit, :rule_type => "WBRS"}
        end
      end

      if sbrs_api_rulehits.present?
        sbrs_api_rulehits.each do |rule_hit|
          DisputeRuleHit.create(rule_type:'SBRS', name: rule_hit, dispute_entry_id: new_dispute_entry.id)
          rule_hits_snapshot << {:name => rule_hit, :rule_type => "SBRS"}
        end
      end

      th_packet[:rule_hits] = rule_hits_snapshot.to_json
      TelemetryHistory.save_dispute_entry_snapshot(th_packet, new_dispute_entry, true)
      return new_dispute_entry
    rescue Exception => ex
      log_exception(ex)
      raise Exception.new("{DisputeEntry creation error: {content: #{ip_url},error:#{ex}}}")
    end


  end

  def self.get_primary_category(uri)
    begin
      prefix_results = Wbrs::Prefix.where({:urls => [uri]})
    rescue => except
      Rails.logger.error("Something is wrong with RuleAPI connection")
      Rails.logger.error(except)
      Rails.logger.error(except.backtrace.join("\n"))

      return {}
    end

    return {} unless prefix_results.any?

    parsed_uri = Complaint.parse_url(uri)
    parsed_uri['path'] = '' unless parsed_uri['path'].present?
    parsed_uri['subdomain'] = '' unless parsed_uri['subdomain'].present?

    final_results = []

    prefix_results.each do |prefix_result|
      if ((prefix_result.subdomain == parsed_uri['subdomain']) || (parsed_uri['subdomain'] == 'www')) && prefix_result.path == parsed_uri['path']
        final_results << prefix_result
      end
    end

    return {} unless final_results.any?

    # category_ids = final_results.first.categories.sort_by(&:confidence).map {|category| category.category_id}
    category_names = final_results.first.categories.sort_by(&:confidence).map {|category| category.descr}
    category_names[0]
    # {category_ids: category_ids, category_names: category_names}
  end


  def self.is_ip?(ip)
    !!IPAddr.new(ip) rescue false
  end

  def self.new_from_wlbl(wlbl)
    new(uri: wlbl.url).tap do |entry|
      entry.wbrs_xlist = [ wlbl ]
    end
  end

  def self.from_age_report_params(params)
    query = resolved_date(params['date_from'], params['date_to'])

    if params['resolution'].present?
      query = query.where(resolution: params['resolution'])
    end

    if params['engineer'].present?
      query = query.joins(dispute: :user).where(users: {cvs_username: params['engineer']})
    end

    if params['customer_id'].present?
      query = query.joins(:dispute).where(disputes: {customer_id: params['customer_id']})
    end

    query
  end

  def hostlookup
    case
    when self.entry_type == "IP"
      self.ip_address
    when self.entry_type == "URI/DOMAIN"
      self.uri
    else
      self.uri.blank? ? self.ip_address : self.uri
    end
  end

  def parse_url(url = self.hostlookup)
    uri = URI.parse(URI.parse(url).scheme.nil? ? "http://#{url}" : url)
    domain = PublicSuffix.parse(uri.host, :ignore_private => true)
    subdomain = uri.host.gsub(Regexp.new("\\.?#{domain.domain}$"), '')

    {
        subdomain: subdomain,
        domain: domain.domain,
        path: uri.path
    }
  end

  def self.safe_domain_of(url)
    begin
      url = url.strip
      url = url.split("/").map {|m| SimpleIDN.to_ascii(m)}.join("/")
      if !url.start_with?( 'http', 'https')
        url = "http://" + url
      end

      clean_url = Addressable::URI.parse(url)
      clean_host = clean_url.host
    rescue
      clean_host = url
    end
    
    clean_host
  end

  def self.domain_of(url)
    url = url.strip
    if !url.start_with?( 'http', 'https')
      url = "http://" + url
    end

    clean_url = Addressable::URI.parse(url)
    clean_host = clean_url.host
    clean_host.sub(/^www\./, '')
  end

  def self.domain_of_with_path(urls)
    if urls.kind_of?(String)
      if !urls.start_with?( 'http', 'https')
        urls = "http://" + urls
      end

      clean_url = Addressable::URI.parse(urls.strip)
      clean_host = clean_url.host.sub(/^www\./, '')
      clean_host = clean_host + clean_url.path

      response = clean_host
    elsif urls.kind_of?(Array)
      response = []
      urls.each do |url|
        if url.strip != ''
          if !url.start_with?( 'http', 'https')
            url = "http://" + url
          end

          clean_url = Addressable::URI.parse(url.strip)
          clean_host = clean_url.host.sub(/^www\./, '')
          clean_host = clean_host + clean_url.path

          response << clean_host
        end
      end
    end

    response
  end

  def assign_url_parts(url = self.hostlookup)

    if !url.starts_with?("http")
      url = "http://" + url
    end

    # Addressable::URI.parse(url)
    uri_parsed = Addressable::URI.parse(url)
    unless uri_parsed.scheme.present? || url.starts_with?('//')
      uri_parsed = Addressable::URI.parse("http://#{url}")
    end
    public_suffix = PublicSuffix.parse(uri_parsed.host, :ignore_private => true)

    self.subdomain                      = uri_parsed.host.gsub(Regexp.new("\\.?#{public_suffix.domain}$"), '')
    self.domain                         = public_suffix.domain
    self.path                           = uri_parsed.path
    self.hostname                       = uri_parsed.host
    self.top_level_domain               = public_suffix.tld

    self
  end

  def ti_status
    RESOLVED == status ? Dispute::TI_RESOLVED : Dispute::TI_NEW
  end

  def blacklist(reload: false)
    @blacklist_loaded = false if reload
    unless @blacklist_loaded
      @blacklist =
          if dispute_entry_preload.present? && dispute_entry_preload.wlbl.present?
            RepApi::Blacklist.load_from_prefetch(dispute_entry_preload.wlbl).first
          else
            begin
              RepApi::Blacklist.where(entries: [ hostlookup ]).first
            rescue
              nil
            end
          end
      @blacklist_loaded = true
    end
    @blacklist
  end

  def classifications
    @classifications ||= blacklist&.classifications || []
  end

  def wbrs_list_type
    @wbrs_list_type ||= wbrs_xlist.select{ |wlbl| wlbl.state == "active" && wlbl.url == self.hostlookup}.map{ |wlbl| wlbl.list_type }.join(', ')
  end

  def wbrs_xlist
    @wbrs_xlist ||=
        if dispute_entry_preload.present? && dispute_entry_preload.crosslisted_urls.present?
          Wbrs::ManualWlbl.load_from_prefetch(dispute_entry_preload.crosslisted_urls)
        else
          Wbrs::ManualWlbl.where({:url => DisputeEntry.domain_of(hostlookup)})
        end
  rescue => except
    Rails.logger.warn "Populating xlist from Wbrs failed."
    Rails.logger.warn "Hostlookup:" + hostlookup
    Rails.logger.warn except
    Rails.logger.warn except.backtrace.join("\n")

    return []
  end

  def virustotals
    #@virustotals = self.virustotal
    #return @virustotals if @virustotals.present?

    unless @virustotals
      if dispute_entry_preload.present? && dispute_entry_preload.virustotal.present?
        virustotal_data = Virustotal::GetVirustotal.load_from_prefetch(dispute_entry_preload.virustotal)
      else
        begin
          virustotal_data = Virustotal::GetVirustotal.by_domain(hostlookup)
        rescue
          virustotal_data = {"scans" => []}
        end
      end
      #scans = Virustotal::GetVirustotal.by_domain(hostlookup)["scans"]
      scans = virustotal_data["scans"]
      sordiddata = Array.new
      unless scans.nil?
        scans_clean = Array.new
        scans_hit = Array.new
        scans_unrated = Array.new
        scans.each do |s|
          item = {:name => s[0], :result => s[1]["result"]}
          case item[:result]
          when "clean site"
            scans_clean << item
          when "unrated site"
            scans_unrated << item
          else
            scans_hit << item
          end
        end
        scans_hit.each { |hit| sordiddata << hit }
        scans_unrated.each { |hit| sordiddata << hit }
        scans_clean.each { |hit| sordiddata << hit }
      end
      @virustotals = sordiddata
    end
    @virustotals
  end

  def virustotals_negatives_count
    virustotals.count {|vt| vt[:result] != "clean site" && vt[:result] != "unrated site" }
  end

  def xbrs_timeline
    if self.new_record?
      if self.uri.present?
        timeline = K2::History.url_lookup(self.uri)
      elsif self.ip_address.present?
        timeline = K2::History.ip_lookup(self.ip_address)
      else
        return []
      end
      timeline.body&.dig('queryResults')&.first['timelines'] || []
    else
      sync_up unless dispute_entry_preload

      cached_data = JSON.parse(self.reload.dispute_entry_preload.xbrs_history)

      if JSON.parse(self.reload.dispute_entry_preload.xbrs_history).is_a?(Array)# determine if preload record contains data from XBRS or K2
        timeline = entry_type == 'IP' ? K2::History.ip_lookup(ip_address) : K2::History.url_lookup(uri)
        data = timeline.body.dig('queryResults')&.first['timelines']
        self.reload.dispute_entry_preload.update(xbrs_history: {k2: data}.to_json)
        data || []
      else
        cached_data['k2'] || []
      end
    end

  end
  
  def umbrellaresult
    if dispute_entry_preload.present? && dispute_entry_preload.umbrella.present?
      @umbrellaresult = dispute_entry_preload.umbrella
      return @umbrellaresult
    end

    # TODO: This is a little ugly, being as the same logic exists inside `base.rb` of the Preload model.
    # If time ever permits, refactor it.
    @umbrella = AutoResolve.new.call_umbrella(address: hostlookup)

    pretty_umbrella_status = "Unclassified" # Default or "0"
    if @umbrella.present?
      case
        # Per docs here: https://dashboard.umbrella.com/o/1755319/#overview
      when @umbrella[hostlookup]["status"] == -1
        pretty_umbrella_status = "Malicious"
      when @umbrella[hostlookup]["status"] == 1
        pretty_umbrella_status = "Benign"
      end
    end

    pretty_umbrella_status
  rescue => except
    Rails.logger.warn "Populating umbrella failed"
    Rails.logger.warn "Hostlookup:" + hostlookup
    Rails.logger.warn except
    Rails.logger.warn except.backtrace.join("\n")

    return 'Unable to resolve'
  end

  def latest_comment_date
    comment = self.dispute.dispute_comments.last
    if comment.present?
      return comment.updated_at.strftime("%FT%T")
    else
      "None"
    end
  end

  def latest_email_date
    comment = self.dispute.dispute_emails.last
    if comment.present?
      return comment.updated_at.strftime("%FT%T")
    else
      "None"
    end
  end

  def assign_from_auto_resolve(address:, total_hits:, resolved_at:, dispute_entry:)

    self.status = NEW

    auto_resolve_verdict = AutoResolve.create_from_payload(entry_type, address, total_hits, dispute_entry)

    if auto_resolve_verdict.resolved?
      if auto_resolve_verdict.malicious?
        self.resolution_comment = "Talos has lowered our reputation score for the URL/Domain/Host to block access."
        self.resolution = STATUS_RESOLVED_FIXED_FN
        self.status = STATUS_RESOLVED
        self.case_closed_at = resolved_at
        self.case_resolved_at = resolved_at
      else
        self.resolution_comment = Dispute::AUTORESOLVED_UNCHANGED_MESSAGE
        self.resolution = STATUS_RESOLVED_UNCHANGED
        self.status = STATUS_RESOLVED
        self.case_closed_at = resolved_at
        self.case_resolved_at = resolved_at
      end
    end

    auto_resolve_verdict
  end

  def new_payload_item

    case
    when NEW == status
      payload = {
          status: Dispute::TI_NEW,
          resolution_message: '',
      }
    when STATUS_RESOLVED_FIXED_FN == resolution
      payload = {
          resolution_message: 'Talos has lowered our reputation score for the URL/Domain/Host to block access.',
          resolution: 'FIXED',
          status: Dispute::TI_RESOLVED,
      }
    else
      message =
          if 'IP' == entry_type
            Dispute::AUTORESOLVED_UNCHANGED_MESSAGE
          else
            'The Talos web reputation will remain unchanged, based on available information. If you have further information regarding this URL/Domain/Host that indicates its involvement in malicious activity, please open an escalation with TAC and provide that information.'
          end
      payload = {
          resolution_message: message,
          resolution: 'UNCHANGED',
          status: Dispute::TI_RESOLVED,
      }
    end
    if self.resolution_comment.present? && self.resolution_comment != ""
      payload[:resolution_message] = self.resolution_comment
    end

    payload
  end

  def referenced_tickets
    Dispute.select("disputes.id, disputes.case_opened_at, disputes.created_at").
        joins(:dispute_entries).
        where("dispute_entries.ip_address = ? or dispute_entries.uri = ?", self.hostlookup, self.hostlookup).
        where.not(:dispute_entries => {:dispute_id => self.dispute_id}).
        distinct
  end

  def research_referenced_tickets
    is_ip_address = !!(hostlookup  =~ Resolv::IPv4::Regex)
    if is_ip_address
      references = Dispute.includes(:dispute_entries).where(:dispute_entries => {:ip_address => self.ip_address})
    else
      references = Dispute.includes(:dispute_entries).where(:dispute_entries => {:uri => self.uri})
    end
  end

  def last_submitted
    if self.referenced_tickets.count > 0

      last_submitted = referenced_tickets.order(:created_at).last.created_at
    else
      last_submitted = "N/A"
    end

    return last_submitted
  end

  def is_possible_company_duplicate?
    Dispute.is_possible_company_duplicate?(dispute, hostlookup, entry_type)
  end

  def self.send_status_updates(field_data)
    entities = []
    field_data.each do |entry_id, field_ary|
      if field_ary.any? {|field_hash| %w{status resolution resolution_comment}.include?(field_hash['field'])}
        entities << DisputeEntry.find(entry_id)
      end
    end

    if entities.any?
      begin
        message = Bridge::DisputeEntryUpdateStatusEvent.new
        message.post_entries(entities)
      rescue
        #think of something later, but this will at least gracefully return
        #in development when you  may not have the bridge running
      end
    end
  end

  def sync_up
    dispute_rule_hits.destroy_all
    th_packet = {}
    ::Preloader::Base.fetch_all_api_data(self.hostlookup, self.id)
    #
    extra_wbrs_stuff = nil
    if self.uri.present? && self.web_ips.present?
      web_ips_formatted = self.web_ips.gsub("[", "").gsub("]", "").gsub("\"", "").split(", ")

      extra_wbrs_stuff = Sbrs::Base.combo_call_sds_v3(self.uri, web_ips_formatted)
      wbrs_stuff = Sbrs::Base.remote_call_sds_v3(self.hostlookup, "wbrs")
    else
      wbrs_stuff = Sbrs::Base.remote_call_sds_v3(self.hostlookup, "wbrs")
    end

    wbrs_stuff_rulehits = Sbrs::ManualSbrs.get_rule_names_from_rulehits(wbrs_stuff) rescue nil

    extra_wbrs_stuff_rulehits = Sbrs::ManualSbrs.get_rule_names_from_rulehits(extra_wbrs_stuff) rescue []

    if wbrs_stuff_rulehits.blank?
      wbrs_stuff_rulehits = []
    end

    ip_addr = IPSocket.getaddress(hostlookup) rescue nil
    #if ip_addr
    #  wbrs_stuff_ip = Sbrs::Base.remote_call_sds_v3(ip_addr, "wbrs")
    #  wbrs_stuff_rulehits = wbrs_stuff_rulehits + Sbrs::ManualSbrs.get_rule_names_from_rulehits(wbrs_stuff_ip)
    #  wbrs_stuff_rulehits = wbrs_stuff_rulehits.uniq
    #end


    if extra_wbrs_stuff.present?
      self.score = extra_wbrs_stuff.dig("wbrs", "score")
      th_packet[:multi_ip_score] = self.score rescue nil
      threat_cats = extra_wbrs_stuff["threat_cats"]

      threat_cat_names = []
      if threat_cats.present?
        threat_cat_info = DisputeEntry.threat_cats_from_ids(threat_cats)
        threat_cat_info.each do |name|
          threat_cat_names << name[:name]
        end
        self.multi_wbrs_threat_category = threat_cat_names
        th_packet[:multi_threat_categories] = threat_cat_names.to_json
      end
    end



    self.wbrs_score = wbrs_stuff["wbrs"]["score"] if wbrs_stuff["wbrs"].present?
    th_packet[:wbrs_score] = self.wbrs_score
    if wbrs_stuff["threat_cats"].present?
      threat_cats = wbrs_stuff["threat_cats"]

      threat_cat_names = []

      threat_cat_info = DisputeEntry.threat_cats_from_ids(threat_cats)
      threat_cat_info.each do |name|
        threat_cat_names << name[:name]
      end
      self.wbrs_threat_category = threat_cat_names
      th_packet[:threat_categories] = threat_cat_names.to_json
    end
    rule_hits_snapshot = []
    wbrs_stuff_rulehits.each do |rule_hit|
      new_rule_hit = DisputeRuleHit.new
      new_rule_hit.dispute_entry_id = self.id
      new_rule_hit.name = rule_hit.strip
      new_rule_hit.rule_type = "WBRS"
      new_rule_hit.save
      rule_hits_snapshot << {:name => new_rule_hit.name, :rule_type => new_rule_hit.rule_type}
    end

    multi_rule_hits_snapshot = []
    extra_wbrs_stuff_rulehits.each do |rule_hit|
      new_rule_hit = DisputeRuleHit.new
      new_rule_hit.dispute_entry_id = self.id
      new_rule_hit.name = rule_hit.strip
      new_rule_hit.rule_type = "WBRS"
      new_rule_hit.is_multi_ip_rulehit = true
      new_rule_hit.save
      multi_rule_hits_snapshot << {:name => new_rule_hit.name, :rule_type => new_rule_hit.rule_type}
    end
    th_packet[:multi_rule_hits] = multi_rule_hits_snapshot.to_json rescue nil

    if self.entry_type == "IP"
      sbrs_stuff = Sbrs::ManualSbrs.get_sbrs_data({:ip => self.hostlookup})
      sbrs_stuff_rules = CloudIntel::Reputation.mnemonics_ip(self.hostlookup)


      self.sbrs_score = sbrs_stuff["sbrs"]["score"]
      th_packet[:sbrs_score] = self.sbrs_score rescue nil
      sbrs_stuff_rules.each do |rule_hit|
        new_rule_hit = DisputeRuleHit.new
        new_rule_hit.dispute_entry_id = self.id
        new_rule_hit.name = rule_hit.strip
        new_rule_hit.rule_type = "SBRS"
        new_rule_hit.save
        rule_hits_snapshot << {:name => new_rule_hit.name, :rule_type => new_rule_hit.rule_type}
      end

    end
    th_packet[:rule_hits] = rule_hits_snapshot
    TelemetryHistory.save_dispute_entry_snapshot(th_packet, self, false)
    save
  end

  def update_from_field_data(field_hash)
    attributes = field_hash.inject({}) do |attrs, field_data|
      attrs[field_data['field']] = field_data['new']
      attrs
    end

    if attributes.has_key?('status')
      unless attributes['status'].nil?
        attributes['status'] = attributes['status'].upcase
        if attributes['status'] == DisputeEntry::STATUS_RESOLVED
          resolved_at = Time.now
          attributes['case_closed_at'] = resolved_at
          attributes['case_resolved_at'] = resolved_at
        elsif attributes['status'] == DisputeEntry::ASSIGNED
          assigned_at = Time.now
          attributes['case_accepted_at'] = assigned_at
        end
      end
    end


    if attributes.has_key?('host')
      host = attributes.delete('host')
      if /\A(?<ip_address>\d+\.\d+\.\d+\.\d+)\z/ =~ host
        attributes['entry_type'] = 'IP'
        attributes['ip_address'] = ip_address
      else
        attributes['entry_type'] = 'URI/DOMAIN'
        attributes['hostname'] = host
        attributes['uri'] = host
      end
    end

    if attributes['uri'].present? && attributes['web_ips'].blank?
      resolved_ip = Resolv.getaddress(self.domain_of(self.uri)) rescue nil
      if resolved_ip.present?
        attributes['web_ips'] = resolved_ip
      end
    end


    if attributes['ip_address'].present? && attributes['ip_address'] != self.ip_address
      sync_up
    end
    if attributes['uri'].present? && attributes['uri'] != self.uri
      sync_up
    end

    update!(attributes.slice(*%w{web_ips entry_type ip_address hostname uri status resolution resolution_comment case_accepted_at case_resolved_at case_closed_at}))
  end

  def self.update_from_field_data(field_data)
    field_data.each do |entry_id, field_hash|
      entry = DisputeEntry.find(entry_id)

      entry.update_from_field_data(field_hash)
    end
  end

  def self.entries_of_url(url)
    Wbrs::ManualWlbl.where({:url => url}).map do |wlbl|
      DisputeEntry.new_from_wlbl(wlbl)
    end
  rescue => except

    Rails.logger.warn "Failed while getting entries from WBRS."
    Rails.logger.warn except
    Rails.logger.warn except.backtrace.join("\n")

    []
  end

  ######################################################################################
  def self.process_research_for_uri(research_params)

    url = research_params['uri'].gsub(/\r\n?/, "\n").strip # Remove all white spaces and newlines

    domain_of_url = DisputeEntry.domain_of(url)
    entries = entries_of_url(url)

    invalid_matches = []

    if research_params['scope'] == "strict"
      entries.each do |entry|
        if url != entry.uri || entry.uri != "www." + entry.uri
          invalid_matches << entry
        end
      end
      entries = entries - invalid_matches
    end

    # Make sure there will always be a "www" and "non-www" form to an inputted URL
    # But, only do this if an entry has a `uri` at all; if we already know it's an
    # IP address, there's no need to prepend www.
    # (this is a fix for https://jira.vrt.sourcefire.com/browse/WEB-7679)
    if !url.include?("www.")
      unless entries.find{|entry| entry.uri.present? && (url == "www." + entry.uri)} || (url =~ Resolv::IPv4::Regex)
        entries.prepend DisputeEntry.new(uri: "www."+ url)
      end
    elsif url.include?("www.")
      unless entries.find{|entry| entry.uri.present? && (url.gsub("www.","") == entry.uri)}
        entries.prepend DisputeEntry.new(uri: url.gsub("www.",""))
      end
    end

    # Make sure the inputted URL is added as an entry
    unless entries.find{|entry| url == entry.uri}
      entries.prepend DisputeEntry.new(uri: url)
    end

    # BEGIN LOGIC TO CONSOLIDATE WLBL INFO TO UNIQUE URIS
    entries.each do |entry|
      entry.class.module_eval { attr_accessor :consolidated_wlbl_strings}
      entry.consolidated_wlbl_strings = entry.wbrs_list_type
      entry.primary_category = DisputeEntry.get_primary_category(entry.hostlookup)
    end

    unique_entries = entries.uniq{|e| e.hostlookup}
    duplicate_entries = entries - unique_entries

    duplicate_entries.each do |duplicate_entry|

      unique_entries.select{ |e| e.hostlookup == duplicate_entry.hostlookup}.map do |e|

        if e.consolidated_wlbl_strings.blank? && duplicate_entry.consolidated_wlbl_strings.present?
          e.consolidated_wlbl_strings << duplicate_entry.consolidated_wlbl_strings
        elsif e.consolidated_wlbl_strings.present? && duplicate_entry.consolidated_wlbl_strings.present?
          e.consolidated_wlbl_strings << ", " + duplicate_entry.consolidated_wlbl_strings
        end

      end


    end

    #entries = unique_entries

    #get rid of weird entries

    final_entries = []
    rejected_entries = []
    unique_entries.each do |r_entry|
      entry_domain = DisputeEntry.domain_of(r_entry.hostlookup)
      if entry_domain.include?(domain_of_url)
        final_entries << r_entry
      else
        rejected_entries << r_entry
      end
    end

    entries = final_entries

    # END WLBL LOGIC, WE SHOULD ONLY HAVE UNIQUE URIS NOW


    entries.each do |entry|
      is_ip_address = !!(entry.uri  =~ Resolv::IPv4::Regex)

      wbrs_stuff = Sbrs::Base.remote_call_sds_v3(entry.uri, "wbrs")
      wbrs_stuff_rulehits = Sbrs::ManualSbrs.get_rule_names_from_rulehits(wbrs_stuff) rescue []
      if wbrs_stuff_rulehits.blank?
        wbrs_stuff_rulehits = []
      end

      ip_addr = IPSocket.getaddress(entry.uri) rescue nil

      if ip_addr.blank?
        ip_addr = Resolv.getaddress(self.domain_of(entry.uri)) rescue nil
      end

      if ip_addr
        #wbrs_stuff_ip = Sbrs::Base.remote_call_sds_v3(ip_addr, "wbrs")
        #wbrs_stuff_rulehits = wbrs_stuff_rulehits + (Sbrs::ManualSbrs.get_rule_names_from_rulehits(wbrs_stuff_ip) rescue [])
        #wbrs_stuff_rulehits = wbrs_stuff_rulehits.uniq
        entry.web_ips = ip_addr
        web_ips_formatted = entry.web_ips.gsub("[", "").gsub("]", "").gsub("\"", "").split(", ")

        extra_wbrs_stuff = Sbrs::Base.combo_call_sds_v3(entry.uri, web_ips_formatted)
        extra_wbrs_stuff_rulehits = Sbrs::ManualSbrs.get_rule_names_from_rulehits(extra_wbrs_stuff) rescue []

        if extra_wbrs_stuff.present?
          entry.score = extra_wbrs_stuff["wbrs"]["score"]

          threat_cats = extra_wbrs_stuff["threat_cats"]

          threat_cat_names = []
          if threat_cats.present?
            threat_cat_info = DisputeEntry.threat_cats_from_ids(threat_cats)
            threat_cat_info.each do |name|
              threat_cat_names << name[:name]
            end
            entry.multi_wbrs_threat_category = threat_cat_names
          end
        end


        extra_wbrs_stuff_rulehits.each do |rule_hit|
          new_rule_hit = DisputeRuleHit.new
          new_rule_hit.name = rule_hit.strip
          new_rule_hit.rule_type = "WBRS"
          new_rule_hit.is_multi_ip_rulehit = true
          entry.dispute_rule_hits << new_rule_hit
        end
      end

      if wbrs_stuff.kind_of?(Hash)
        entry.wbrs_score = wbrs_stuff["wbrs"]["score"]
      else
        entry.wbrs_score = nil
      end

      wbrs_stuff_rulehits.each do |rule_hit|
        new_rule_hit = DisputeRuleHit.new
        new_rule_hit.dispute_entry_id = entry.id
        new_rule_hit.name = rule_hit.strip
        new_rule_hit.rule_type = "WBRS"
        entry.dispute_rule_hits << new_rule_hit
      end

      if is_ip_address === true
        sbrs_stuff = Sbrs::ManualSbrs.get_sbrs_data({:ip => entry.uri})
        entry.sbrs_score = sbrs_stuff["sbrs"]["score"]
        sbrs_stuff_rules = CloudIntel::Reputation.mnemonics_ip(entry.uri)

        sbrs_stuff_rules.each do |rule_hit|
          new_rule_hit = DisputeRuleHit.new
          new_rule_hit.dispute_entry_id = entry.id
          new_rule_hit.name = rule_hit.strip
          new_rule_hit.rule_type = "SBRS"
          entry.dispute_rule_hits << new_rule_hit
        end
      end
    end

    entries
  end


  # If the research page is served from the DisputesController, this method is here.
  # If the controller action is moved to another controller, move this method to another class.
  def self.research_results(research_params)
    if research_params.present? && research_params['uri'].strip != ''
      total_uris = research_params['uri'].split("\r\n")
      final_uris = []

      total_uris.each do |uri|
        result_r = uri.split("\r")
        result_n = uri.split("\n")
        result_u = uri.split("\u2028")
        result_s = uri.split(" ")


        final_result = []

        was_split = false

        if result_r.size > 1
          final_result += result_r
          was_split = true
        end

        if result_n.size > 1
          final_result += result_n
          was_split = true
        end

        if result_u.size > 1
          final_result += result_u
          was_split = true
        end

        if result_s.size > 1
          final_result += result_s
          was_split = true
        end

        if was_split == false
          final_uris << uri
        end

        final_result = final_result.uniq

        if final_result.size > 1
          final_uris += final_result
        end

      end

      final_uris = final_uris.flatten

      result_set = []

      final_uris.each do |uri|
        args = {}
        args['uri'] = uri
        args['scope'] = research_params['scope']
        search_results = process_research_for_uri(args)
        result_set += search_results
      end

      result_set = result_set.flatten

      result_set
    else
      []
    end
  end


  def self.check_for_duplicates(entry)
    DisputeEntry.where("ip_address = ? or uri = ?", entry, entry).present?
  end

  def self.valid_url?(test_url)
    test_url =~ URI::regexp ? true : false
  end
  
  def self.process_multi_ip_info(uri, ips, dispute_entry = nil)

    all_rulehits = Wbrs::RuleHit.all
    rule_hit_info = []
    result = {}

    results = Sbrs::Base.combo_call_sds_v3(uri, ips)

    ip_addresses = ips
    wbrs_rule_hits = Sbrs::ManualSbrs.get_rule_names_from_rulehits(results) rescue nil
    wbrs_score = results["wbrs"]["score"]
    proxy_uri = results["proxy_uri"]
    threat_cats = results["threat_cats"]


    threat_cat_names = []
    if threat_cats.present?
      threat_cat_info = threat_cats_from_ids(threat_cats)
      threat_cat_info.each do |name|
        threat_cat_names << name[:name]
      end
      threat_cat_names
    end



    if dispute_entry.present?
      unless wbrs_rule_hits.nil?
        rule_hits_to_destroy = dispute_entry.dispute_rule_hits.where(:is_multi_ip_rulehit => true)

        ###

        rule_hits_to_destroy.destroy_all

        wbrs_rule_hits.each do |rule_hit|
          DisputeRuleHit.create(rule_type:'WBRS', name: rule_hit, dispute_entry_id: dispute_entry.id, is_multi_ip_rulehit: true)
          
          rule_hit_data = all_rulehits.find {|rulehit| rulehit.mnemonic == rule_hit}
          if rule_hit_data.present?
            rule_hit_info << {:mnemonic => rule_hit, :malware_probability => rule_hit_data.probability, :description => rule_hit_data.description}
          else
            rule_hit_info << {:mnemonic => rule_hit}
          end
        end
      end

      dispute_entry.multi_wbrs_threat_category = threat_cat_names
      dispute_entry.proxy_url = proxy_uri
      dispute_entry.score = wbrs_score
      dispute_entry.web_ips = ip_addresses
      dispute_entry.save

    end



    result[:threat_cats] = threat_cat_names
    result[:proxy_uri] = proxy_uri
    result[:rulehits] = rule_hit_info
    result[:score] = wbrs_score

    return result
  end


  def self.verdict_from_score(score)
    verdict = ""
    if score >= 6.0
      verdict = "Trusted"
    end
    if score > 0 && score < 6.0
      verdict = "Favorable"
    end
    if score >= -3 && score <= 0
      verdict = "Neutral"
    end
    if score > -6 && score < -3
      verdict = "Questionable"
    end
    if score <= -6
      verdict = "Untrusted"
    end

    verdict
  end

  def self.email_verdict_from_score(score)

    # Poor is -10 to -2.0
    # Neutral is -1.9 to 0.9
    # Neutral (score none) <= no longer the case?
    # Good is +1.0 to +10
    verdict = ""

    begin

      score = Float(score)
      if score > 10.0 || score < -10.0
        score = score.to_f / 10.0
      end
      case
      when score >= 1.0                 # Good is +1.0 to +10
        verdict = 'Good'
      when score > -2.0                 # Neutral is -1.9 to 0.9
        verdict = 'Neutral'
      when score <= -2.0                # Poor is -10 to -2.0
        verdict = 'Poor'
      else
        verdict = ''
      end

    rescue
      verdict = ''
    end

    verdict

  end


  def running_verdict
    if @running_verdict.blank?

      wbrs_stuff = Sbrs::Base.remote_call_sds_v3(self.hostlookup, "wbrs")

      raw_score = wbrs_stuff["wbrs"]["score"]

      if self.entry_type == "URI/DOMAIN"
        @running_verdict = self.class.verdict_from_score(raw_score)
      else
        @running_verdict = self.class.email_verdict_from_score(self.sbrs_score.to_f/10.0)
      end
    end
    @running_verdict
  end

  def self.threat_cats_from_ids(ids)
    results = JSON.parse(Sbrs::Base.remote_call_sds_v3("", "threatcat_labels"))

    response = []

    ids.each do |id|
      threat_cat = {}
      threat_cat[:id] = id
      threat_cat[:mnemonic] = results[id.to_s]["mnemonic"]
      threat_cat[:name] = results[id.to_s]["name"]
      threat_cat[:description] = results[id.to_s]["description"]

      response << threat_cat
    end

    response
  end

  def self.matching_disposition_toggle

    begin
      begin
        return AppConfig.matching_disposition_toggle
      rescue
        return Rails.configuration.auto_resolve.check_matching_disposition
      end
    rescue Exception => e
      Rails.logger.error(e.message)
      return false
    end
  end

  def is_disposition_matching?(entry_claim, is_umbrella=false)

    begin

      if !self.class.matching_disposition_toggle
        return false
      end

      wbrs_stuff = Sbrs::Base.remote_call_sds_v3(self.hostlookup, "wbrs")
      sbrs_api_response = Sbrs::ManualSbrs.call_sbrs('ip' => self.hostlookup)
      raw_sbrs_score = sbrs_api_response['sbrs']['score'] rescue nil
      raw_wbrs_score = wbrs_stuff["wbrs"]["score"] rescue nil

      extra_wbrs_stuff = Sbrs::Base.combo_call_sds_v3(self.hostlookup, [])
      extra_wbrs_stuff_rulehits = Sbrs::ManualSbrs.get_rule_names_from_rulehits(extra_wbrs_stuff) rescue []

      includes_phishtank_rulehit = extra_wbrs_stuff_rulehits.include?("phtk")

      submission_type = self.dispute.submission_type

      if submission_type == "e"
        raw_score = raw_sbrs_score
      end
      if submission_type == "w"
        raw_score = raw_wbrs_score
      end

      if entry_claim == "false negative"

        if submission_type == "w"

          if is_umbrella == true
            if raw_score.present? && raw_score.to_f <= -6.0
              self.status = STATUS_RESOLVED
              self.resolution = STATUS_AUTO_RESOLVED_MATCH
              self.resolution_comment = "This case was resolved by automation due to the submission already having a blocking score. Talos does not reduce the reputation of already inaccessible submissions as this would affect the way our automated system functions. If one of our customers is able to access the submission, that is due to relaxed settings on their side and can only be fixed locally by that customer. If you would like this to be reviewed further, please open a TAC case."
              self.save

              return true
            end
          else

            if raw_score.present? && raw_score.to_f <= -6.0
              self.status = STATUS_RESOLVED
              self.resolution = STATUS_AUTO_RESOLVED_MATCH
              if self.dispute.submitter_type == "NON-CUSTOMER"

                self.resolution_comment = AutoResolve.generate_generic_blocking_message(self.hostlookup, false)
              else

                self.resolution_comment = AutoResolve.generate_generic_blocking_message(self.hostlookup, true)
              end

              self.save

              return true
            end

          end

        end

        if submission_type == "e"
          if raw_score.present? && raw_score.to_f <= -2.0
            self.status = STATUS_RESOLVED
            self.resolution = STATUS_AUTO_RESOLVED_MATCH
            if self.dispute.submitter_type == "NON-CUSTOMER"
              self.resolution_comment = "This case was resolved by automation due to the submission already having a blocking score. Talos does not decrease the reputation of already inaccessible submissions as this would affect the way our automated system functions. If one of our customers can access the submission, that is due to lax settings on their side and can only be fixed locally by that customer."
            else
              self.resolution_comment = "This case was resolved by automation due to the submission already having a blocking score. Talos does not decrease the reputation of already inaccessible submissions as this would affect the way our automated system functions. If one of our customers can access the submission, that is due to lax settings on their side and can only be fixed locally by that customer. If you would like this to be reviewed further, please open a Cisco TAC case."
            end

            self.save

            return true

          end
        end

      end

      if entry_claim == "false positive"

        if is_umbrella == true
          return false
        else

          if submission_type == "w"


            if raw_score.present? && raw_score.to_f <= -6.0
              return false
            end

            results = RepApi::Blacklist.where(entries: [ self.hostlookup ]) rescue nil
            if results.kind_of?(Array)
              is_blacklisted = results.any?{|result| result.status.upcase == "ACTIVE"} rescue true
            else
              is_blacklisted = results.status.upcase == "ACTIVE" rescue true
            end

            #WEB-10157
            #if is blacklisted OR has phishtank rulehit, then send to auto resolve : else hit the below block matching disposition/cat check
            # true || true === !false && !false
            #De Morgan's Laws always catch me off guard.
            if !is_blacklisted && !includes_phishtank_rulehit

              ###SHUTTING DOWN WEBCAT CHECK AND CONVERT
              # reason I'm not just removing the code is for convenience.  I have reason to believe this will be coming back in the future
              # when TE/SDO have fleshed out the troublesome procedural edge cases that plagued this initial release in prod environment.

              ##Check for web category existence, as no-category can be a source of blocking on some network setups

              #current_cat = DisputeEntry.get_primary_category(self.hostlookup)
              #for now, only take this path when single entry ticket

              #if current_cat.blank? && self.dispute.dispute_entries.size == 1
                # ticket conversion action here
              #  conversion_packet = {}
              #  conversion_packet[:dispute_id] = self.dispute.id
              #  conversion_packet[:summary] = self.dispute.problem_summary
              #  conversion_packet[:suggested_categories] = []
              #  conversion_packet[:suggested_categories] << [{}, {"entry" => self.hostlookup, "suggested_categories" => "Business and Industry"}]
              #  user = User.where(cvs_username:"vrtincom").first

              #  Dispute.convert_to_complaint(conversion_packet, user, true)

              #  return true
              #end


              self.status = STATUS_RESOLVED
              self.resolution = STATUS_AUTO_RESOLVED_MATCH

              if self.dispute.submitter_type == "NON-CUSTOMER"
                self.resolution_comment = AutoResolve.generate_generic_non_blocking_message(self.hostlookup, raw_score, false)
              else
                self.resolution_comment = AutoResolve.generate_generic_non_blocking_message(self.hostlookup, raw_score,true)
              end

              self.save

              return true
            end

          end

          if submission_type == "e"

            if raw_score.present? && raw_score.to_f < -1.9
              return false
            end

            self.status = STATUS_RESOLVED
            self.resolution = STATUS_AUTO_RESOLVED_MATCH

            if self.dispute.submitter_type == "NON-CUSTOMER"
              self.resolution_comment = "This case was resolved by automation due to the submission already having a non-blocking score. Talos does not improve the reputation of already accessible submissions as this would affect the way our automated system functions. If one of our customers cannot access the submission, that is due to aggressive settings on their side and can only be fixed locally by that customer."
            else
              self.resolution_comment = "This case was resolved by automation due to the submission already having a non-blocking score. Talos does not improve the reputation of already accessible submissions as this would affect the way our automated system functions. If one of our customers cannot access the submission, that is due to aggressive settings on their side and can only be fixed locally by that customer. If you would like this to be reviewed further, please open a Cisco TAC case."
            end

            self.save

            return true

          end

        end

      end


      return false

    rescue => e
      Rails.logger.error e
      Rails.logger.error e.backtrace.join("\n")
      return false
    end
  end

  def determine_platform
    if self.platform_id.present?
      return (self.product_platform.public_name rescue "No Data")
    end
    if self.dispute.platform_id.present?
      return (self.dispute.platform.public_name rescue "No Data")
    end
    if self.platform.present?
      return (self.platform rescue "No Data")
    end

    return nil
  end

  def determine_platform_record
    if self.platform_id.present?
      return (self.product_platform rescue nil)
    end
    if self.dispute.platform_id.present?
      return (self.dispute.platform rescue nil)
    end

    return nil
  end
end
