require 'socket'

class DisputeEntry < ApplicationRecord
  attr_writer :wbrs_xlist

  attr_accessor :running_verdict

  has_paper_trail on: [:update], ignore: [:updated_at, :entry_type]
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

  after_initialize do |dispute_entry|
    is_ip_address = !!(dispute_entry.uri =~ Resolv::IPv4::Regex)

    if is_ip_address
      dispute_entry.ip_address = dispute_entry.uri
      dispute_entry.uri = nil
      dispute_entry.entry_type = "IP"
      dispute_entry.hostname = nil
    end

  end

  def self.create_dispute_entry(dispute, ip_url, status = NEW)
    begin
      new_dispute_entry = DisputeEntry.new
      new_dispute_entry.dispute_id = dispute.id
      new_dispute_entry.status = status

      sbrs_api_rulehits = nil
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

            threat_cats = extra_wbrs_stuff["threat_cats"]

            threat_cat_names = []
            if threat_cats.present?
              threat_cat_info = DisputeEntry.threat_cats_from_ids(threat_cats)
              threat_cat_info.each do |name|
                threat_cat_names << name[:name]
              end
              new_dispute_entry.multi_wbrs_threat_category = threat_cat_names
            end
          end
          new_dispute_entry.save

          extra_wbrs_stuff_rulehits.each do |rule_hit|
            new_rule_hit = DisputeRuleHit.new
            new_rule_hit.dispute_entry_id = new_dispute_entry.id
            new_rule_hit.name = rule_hit.strip
            new_rule_hit.rule_type = "WBRS"
            new_rule_hit.is_multi_ip_rulehit = true
            new_rule_hit.save
          end

        end




      end

      new_dispute_entry.save!
      ::Preloader::Base.fetch_all_api_data(ip_url, new_dispute_entry.id)
      # Create Dispute Entry RuleHits
      wbrs_rule_hits = Sbrs::ManualSbrs.get_rule_names_from_rulehits(wbrs_api_response)

      if wbrs_rule_hits.present?
        wbrs_rule_hits.each do |rule_hit|
          DisputeRuleHit.create(rule_type:'WBRS', name: rule_hit, dispute_entry_id: new_dispute_entry.id)
        end
      end

      if sbrs_api_rulehits.present?
        sbrs_api_rulehits.each do |rule_hit|
          DisputeRuleHit.create(rule_type:'SBRS', name: rule_hit, dispute_entry_id: new_dispute_entry.id)
        end
      end
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

  def self.domain_of(url)
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

    uri = URI.parse(URI.parse(url).scheme.nil? ? "http://#{url}" : url)
    domain = PublicSuffix.parse(uri.host, :ignore_private => true)

    self.subdomain                      = uri.host.gsub(Regexp.new("\\.?#{domain.domain}$"), '')
    self.domain                         = domain.domain
    self.path                           = uri.path
    self.hostname                       = uri.host
    self.top_level_domain               = domain.tld

    self
  end

  def ti_status
    RESOLVED == status ? Dispute::TI_RESOLVED : Dispute::TI_NEW
  end

  def get_xbrs_value

    if dispute_entry_preload.present? && dispute_entry_preload.xbrs_history.present?
      xbrs = Xbrs::GetXbrs.load_from_prefetch(dispute_entry_preload.xbrs_history)
    else
      case
        when self.entry_type == "IP"
          begin
            xbrs = Xbrs::GetXbrs.by_ip4(self.ip_address.gsub(/\r\n?/, "\n").strip)
          rescue Exception => e
            Rails.logger.error e
            Rails.logger.error e&.backtrace&.join("\n")
            Rails.logger.info e
            Rails.logger.error e&.backtrace&.join("\n")
            Rails.logger.warn e
            Rails.logger.error e&.backtrace&.join("\n")
            xbrs = [{}, {'data' => [], 'legend' => []}]
          end
        when self.entry_type == "URI/DOMAIN"
          begin
            xbrs = Xbrs::GetXbrs.by_domain(self.uri.gsub(/\r\n?/, "\n").strip)
          rescue Exception => e
            Rails.logger.error e
            Rails.logger.error e&.backtrace&.join("\n")
            Rails.logger.info e
            Rails.logger.error e&.backtrace&.join("\n")
            Rails.logger.warn e
            Rails.logger.error e&.backtrace&.join("\n")
            xbrs = [{}, {'data' => [], 'legend' => []}]
          end
      else
        begin
          self.uri.blank? ? xbrs = Xbrs::GetXbrs.by_ip4(self.ip_address) : xbrs = Xbrs::GetXbrs.by_domain(self.uri.gsub(/\r\n?/, "\n").strip)
        rescue Exception => e
          Rails.logger.error e
          Rails.logger.error e&.backtrace&.join("\n")
          Rails.logger.info e
          Rails.logger.error e&.backtrace&.join("\n")
          Rails.logger.warn e
          Rails.logger.error e&.backtrace&.join("\n")
          xbrs = [{}, {'data' => [], 'legend' => []}]
        end
      end
    end
    if xbrs[1].blank?
      xbrs = [{}, {'data' => [], 'legend' => []}]
    end

    # Starting here, we are cleaning up this data to remove columns that are completely empty.
    datacounter = 0
    @columns_to_remove = []
    while (datacounter < xbrs[1]['data'].length)
      i = 0
      nil_entries = []
      while (i < xbrs[1]['data'][datacounter].length)
        nil_entries = xbrs[1]['data'][datacounter].each_index.select{ |v| !xbrs[1]['data'][datacounter][v].present? }
        i += 1
      end

      @columns_to_remove << nil_entries

      datacounter += 1
    end

    if @columns_to_remove.reduce(:&)
      @columns_to_remove = @columns_to_remove.reduce(:&)
      xbrs[1]['data'].each do |data_row|
        data_row.delete_if.with_index{|_, index| @columns_to_remove.include? index}
      end
      xbrs[1]['legend'].delete_if.with_index{|_, index| @columns_to_remove.include? index}
    end
    # End remove empty columns

    xbrs
  end
  #TODO: find a better way to handle large xbrs results
  #right now it's capped at 100 entries if data size is greater than 1,000. I suspect that will not fly with analysts in the long run.
  def find_xbrs(reload: false)
    @xbrs = nil if reload
    @xbrs ||= get_xbrs_value

    formatted_data = []
    formatted_data << {}
    formatted_data << {}
    formatted_data.last['data'] = []
    formatted_data.last['legend'] = @xbrs.last['legend']
    data = @xbrs.last['data']
    columns = @xbrs.last['legend']

    mtime_column_index = nil
    ctime_column_index = nil

    columns.each_with_index do |col, index|
      if col == 'ctime'
        ctime_column_index = index
      end
      if col == 'mtime'
        mtime_column_index = index
      end
    end

    if data.size > 1000
      doable_data = data.first(100)
    else
      doable_data = data
    end
    doable_data.each do |datum|
      if ctime_column_index
        datum[ctime_column_index] = Time.at(datum[ctime_column_index])
      end
      if mtime_column_index
        datum[mtime_column_index] = Time.at(datum[mtime_column_index])
      end

      formatted_data.last['data'] << datum

    end

    columns_to_remove = %w(rule_id row_id genid cidr exclusion ip proto userpass port query fragment attr attr_truncated path_truncated query_truncated unique_hash)
    is_ip_address = !!(self.uri  =~ Resolv::IPv4::Regex)
    if is_ip_address
      # If this is an IP address, we can also remove the 'subdomain' and 'path' headers
      columns_to_remove << 'subdomain'
      columns_to_remove << 'path'
    end


    indices_to_delete = []
    formatted_data[1]['legend'].each_with_index do |name, index|
      if columns_to_remove.include? name
        indices_to_delete << index
      end
    end

    formatted_data[1]['legend'] = formatted_data[1]['legend'].reject.with_index { |e, i| indices_to_delete.include? i }
    formatted_data[1]['data'].each_with_index do |d, index|
      formatted_data[1]['data'][index] = d.reject.with_index { |e, i| indices_to_delete.include? i}
    end


    formatted_data

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

  def xbrs_data
    # Current XBRS hits for a URL
    # This method is different from `xbrs_history` because of https://jira.vrt.sourcefire.com/browse/WEB-6770
    result = find_xbrs[1]
    current_array = []
    result['data'].each do |data|
      if data.last == "full"
        current_array << data
      end
    end
    result['data'] = current_array
    result

  end

  def xbrs_history
    # XBRS history for a URL
    # This method is different from `xbrs_data` because of https://jira.vrt.sourcefire.com/browse/WEB-6770
    result = find_xbrs[1]
    current_array = []
    result['data'].each do |data|
      if data.last != "full"
        current_array << data
      end
    end
    result['data'] = current_array
    result
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
    is_ip_address = !!(hostlookup =~ Resolv::IPv4::Regex)
    if is_ip_address
      references = Dispute.includes(:dispute_entries).where(:dispute_entries => {:ip_address => self.ip_address}).where.not(:dispute_entries => {:dispute_id => self.dispute_id})
    else
      references = Dispute.includes(:dispute_entries).where(:dispute_entries => {:uri => self.uri}).where.not(:dispute_entries => {:dispute_id => self.dispute_id})
    end
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
      self.score = extra_wbrs_stuff["wbrs"]["score"]

      threat_cats = extra_wbrs_stuff["threat_cats"]

      threat_cat_names = []
      if threat_cats.present?
        threat_cat_info = DisputeEntry.threat_cats_from_ids(threat_cats)
        threat_cat_info.each do |name|
          threat_cat_names << name[:name]
        end
        self.multi_wbrs_threat_category = threat_cat_names
      end
    end



    self.wbrs_score = wbrs_stuff["wbrs"]["score"]

    if wbrs_stuff["threat_cats"].present?
      threat_cats = wbrs_stuff["threat_cats"]

      threat_cat_names = []

      threat_cat_info = DisputeEntry.threat_cats_from_ids(threat_cats)
      threat_cat_info.each do |name|
        threat_cat_names << name[:name]
      end
      self.wbrs_threat_category = threat_cat_names

    end

    wbrs_stuff_rulehits.each do |rule_hit|
      new_rule_hit = DisputeRuleHit.new
      new_rule_hit.dispute_entry_id = self.id
      new_rule_hit.name = rule_hit.strip
      new_rule_hit.rule_type = "WBRS"
      new_rule_hit.save
    end

    extra_wbrs_stuff_rulehits.each do |rule_hit|
      new_rule_hit = DisputeRuleHit.new
      new_rule_hit.dispute_entry_id = self.id
      new_rule_hit.name = rule_hit.strip
      new_rule_hit.rule_type = "WBRS"
      new_rule_hit.is_multi_ip_rulehit = true
      new_rule_hit.save
    end

    if self.entry_type == "IP"
      sbrs_stuff = Sbrs::ManualSbrs.get_sbrs_data({:ip => self.hostlookup})
      sbrs_stuff_rules = CloudIntel::Reputation.mnemonics_ip(self.hostlookup)


      self.sbrs_score = sbrs_stuff["sbrs"]["score"]
      sbrs_stuff_rules.each do |rule_hit|
        new_rule_hit = DisputeRuleHit.new
        new_rule_hit.dispute_entry_id = self.id
        new_rule_hit.name = rule_hit.strip
        new_rule_hit.rule_type = "SBRS"
        new_rule_hit.save
      end

    end

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

    if !url.include?("www.")
      unless entries.find{|entry| url == "www." + entry.uri} || (url =~ Resolv::IPv4::Regex)
        entries.prepend DisputeEntry.new(uri: "www."+ url)
      end
    elsif url.include?("www.")
      unless entries.find{|entry| url.gsub("www.","") == entry.uri}
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
    if is_ip?(entry) && DisputeEntry.where(ip_address: entry).present?
      return true
    elsif is_ip?(entry) && !DisputeEntry.where(ip_address: entry).present?
      return false
    elsif !is_ip?(entry) && DisputeEntry.where(uri: entry).present?
      return true
    elsif !is_ip?(entry) && !DisputeEntry.where(uri: entry).present?
      return false
    end
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

  def is_disposition_matching?(entry_claim, is_umbrella=false)

    begin

      wbrs_stuff = Sbrs::Base.remote_call_sds_v3(self.hostlookup, "wbrs")

      raw_score = wbrs_stuff["wbrs"]["score"]

      if self.entry_type == "URI/DOMAIN"
        @running_verdict = self.class.verdict_from_score(wbrs_stuff["wbrs"]["score"])
      else
        @running_verdict = self.class.email_verdict_from_score(self.sbrs_score)
      end

      if entry_claim == "false negative"

        if is_umbrella == true
          if raw_score.to_f <= -7.0
            self.status = STATUS_RESOLVED
            self.resolution = STATUS_RESOLVED_UNCHANGED
            self.resolution_comment = "This case was resolved by automation due to the submission already having a blocking score. By default, a URL/IP address with a Web Reputation of Untrusted should be inaccessible by our customers. Talos does not reduce the reputation of already inaccessible submissions as this would affect the way our automated system functions. If one of our customers is able to access the submission, that is due to relaxed settings on their side and can only be fixed locally by that customer. If you would like this to be reviewed further, please open a TAC case."
            self.save

            return true
          end
        else

          if self.suggested_disposition == @running_verdict
            self.status = STATUS_RESOLVED
            self.resolution = STATUS_RESOLVED_UNCHANGED
            self.resolution_comment = "This case was resolved by automation due to the submission already having a blocking score. By default, a URL/IP address with a Web Reputation of Untrusted should be inaccessible by our customers. Talos does not reduce the reputation of already inaccessible submissions as this would affect the way our automated system functions. If one of our customers is able to access the submission, that is due to relaxed settings on their side and can only be fixed locally by that customer. If you would like this to be reviewed further, please open a TAC case."
            self.save

            return true
          end

        end

      end

      if entry_claim == "false positive"

        if is_umbrella == true
          return false
        else

          results = RepApi::Blacklist.where(entries: [ self.hostlookup ]) rescue nil

          is_blacklisted = results.any?{|result| result.status == "ACTIVE"} rescue true

          if ['Trusted', 'Favorable', 'Neutral', 'Good', 'Unknown', 'Questionable'].include?(@running_verdict) && !is_blacklisted
            self.status = STATUS_RESOLVED
            self.resolution = STATUS_RESOLVED_UNCHANGED
            self.resolution_comment = "This case was resolved by automation due to the submission already having a non-blocking score. By default, a URL/IP address with a Web Reputation of Trusted, Favorable, Neutral, or Questionable should be accessible by our customers. Talos does not improve the reputation of already accessible submissions as this would affect the way our automated system functions. If one of our customers cannot access the submission, that is due to aggressive settings on their side and can only be fixed locally by that customer. If you would like this to be reviewed further, please open a TAC case."
            self.save

            return true
          end

        end
      end


      return false

    rescue
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

end
