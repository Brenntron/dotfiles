require 'socket'

class DisputeEntry < ApplicationRecord
  attr_writer :wbrs_xlist

  has_paper_trail on: [:update], ignore: [:updated_at, :entry_type]
  belongs_to :dispute
  belongs_to :user, optional: true
  has_many :dispute_rule_hits
  has_one  :dispute_entry_preload

  RESOLVED = "RESOLVED"
  NEW = "NEW"

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

  STATUS_RESOLVED_DUPLICATE = "DUPLICATE"

  delegate :cvs_username, to: :dispute, allow_nil: true

  ASSIGNED = "ASSIGNED"
  CLOSED = "CLOSED"

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

  def self.create_dispute_entry(dispute, ip_url, status = NEW)
    begin
      params = {}
      new_dispute_entry = DisputeEntry.new
      new_dispute_entry.dispute_id = dispute.id
      new_dispute_entry.status = status

      if is_ip?(ip_url)
        params['ip'] = ip_url

        wbrs_api_response = Sbrs::ManualSbrs.call_wbrs(params)
        sbrs_api_response = Sbrs::ManualSbrs.call_sbrs(params)
        sbrs_api_rulehit_response =  Sbrs::GetSbrs.get_sbrs_rules_for_ip(ip_url)
        wbrs_prefix_response = ComplaintEntry.get_category(params['ip'])

        new_dispute_entry.ip_address = ip_url
        new_dispute_entry.entry_type = "IP"
        new_dispute_entry.primary_category = wbrs_prefix_response


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
        params['url'] = ip_url

        wbrs_api_response = Sbrs::ManualSbrs.call_wbrs(params, type: 'wbrs')
        sbrs_api_response = Sbrs::ManualSbrs.call_sbrs(params, type: 'wbrs')
        wbrs_prefix_response = ComplaintEntry.get_category(params['url'])

        url_parts = Complaint.parse_url(ip_url)
        new_dispute_entry.uri = ip_url
        new_dispute_entry.entry_type = "URI/DOMAIN"
        new_dispute_entry.subdomain = url_parts[:subdomain]
        new_dispute_entry.domain = url_parts[:domain]
        new_dispute_entry.path = url_parts[:path]

        new_dispute_entry.primary_category = wbrs_prefix_response

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
      end

      new_dispute_entry.save!

      # Create Dispute Entry RuleHits
      wbrs_rule_hits = Sbrs::ManualSbrs.get_rule_names_from_rulehits(wbrs_api_response)

      if wbrs_rule_hits.present?
        wbrs_rule_hits.each do |rule_hit|
          DisputeRuleHit.create(rule_type:'WBRS', name: rule_hit, dispute_entry_id: new_dispute_entry.id)
        end
      end

      if sbrs_api_rulehit_response.present?
        sbrs_api_rulehit_response.each do |rule_hit|
          DisputeRuleHit.create(rule_type:'SBRS', name: rule_hit, dispute_entry_id: new_dispute_entry.id)
        end
      end

    rescue Exception => e
      raise Exception.new("{DisputeEntry creation error: {content: #{ip_url},error:#{e}}}")
    end


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
    domain = PublicSuffix.parse(uri.host)
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
        url = "http://" + urls
      else
        url = urls
      end

      clean_url = Addressable::URI.parse(url)
      clean_host = clean_url.host.sub(/^www\./, '')
      clean_host = clean_host + clean_url.path

      response = clean_host
    elsif urls.kind_of?(Array)
      response = []
      urls.each do |url|
        if url.strip != ''
          if !url.start_with?( 'http', 'https')
            url = "http://" + url
          else
            url = url
          end

          clean_url = Addressable::URI.parse(url)
          clean_host = clean_url.host.sub(/^www\./, '')
          clean_host = clean_host + clean_url.path

          response << clean_host
        end
      end
    end

    response
  end

  def assign_url_parts(url = self.hostlookup)
    uri = URI.parse(URI.parse(url).scheme.nil? ? "http://#{url}" : url)
    domain = PublicSuffix.parse(uri.host)

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
        xbrs = Xbrs::GetXbrs.by_ip4(self.ip_address.gsub(/\r\n?/, "\n").strip)
      when self.entry_type == "URI/DOMAIN"
        xbrs = Xbrs::GetXbrs.by_domain(self.uri.gsub(/\r\n?/, "\n").strip)
      else
        begin
          self.uri.blank? ? xbrs = Xbrs::GetXbrs.by_ip4(self.ip_address) : xbrs = Xbrs::GetXbrs.by_domain(self.uri.gsub(/\r\n?/, "\n").strip)
        rescue
          xbrs = [{}, {'data' => []}]
        end
      end
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

  def find_xbrs(reload: false)
    @xbrs = nil if reload
    @xbrs ||= get_xbrs_value
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
    @wbrs_list_type ||= wbrs_xlist.map{ |wlbl| wlbl.list_type }.join(', ')
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
    find_xbrs[1]
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
      end
    end

    auto_resolve_verdict
  end

  def new_payload_item
    case
    when NEW == status
      {
          status: Dispute::TI_NEW,
          resolution_message: '',
      }
    when STATUS_RESOLVED_FIXED_FN == resolution
      {
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
      {
          resolution_message: message,
          resolution: 'UNCHANGED',
          status: Dispute::TI_RESOLVED,
      }
    end
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

      last_submitted = referenced_tickets.last.created_at
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

    wbrs_stuff = Sbrs::ManualSbrs.get_wbrs_data({:url => self.hostlookup})
    wbrs_stuff_rulehits = Sbrs::ManualSbrs.get_rule_names_from_rulehits(wbrs_stuff)

    ip_addr = IPSocket.getaddress(hostlookup) rescue nil
    if ip_addr
      wbrs_stuff_ip = Sbrs::ManualSbrs.get_wbrs_data(url: ip_addr)
      wbrs_stuff_rulehits = wbrs_stuff_rulehits + Sbrs::ManualSbrs.get_rule_names_from_rulehits(wbrs_stuff_ip)
      wbrs_stuff_rulehits = wbrs_stuff_rulehits.uniq
    end


    self.wbrs_score = wbrs_stuff["wbrs"]["score"]
    wbrs_stuff_rulehits.each do |rule_hit|
      new_rule_hit = DisputeRuleHit.new
      new_rule_hit.dispute_entry_id = self.id
      new_rule_hit.name = rule_hit.strip
      new_rule_hit.rule_type = "WBRS"
      new_rule_hit.save
    end

    if self.entry_type == "IP"
      sbrs_stuff = Sbrs::ManualSbrs.get_sbrs_data({:ip => self.hostlookup})
      sbrs_stuff_rules = Sbrs::GetSbrs.get_sbrs_rules_for_ip(self.hostlookup)

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

    if attributes['ip_address'].present? && attributes['ip_address'] != self.ip_address
      sync_up
    end
    if attributes['uri'].present? && attributes['uri'] != self.uri
      sync_up
    end

    update!(attributes.slice(*%w{entry_type ip_address hostname uri status resolution resolution_comment case_accepted_at case_resolved_at case_closed_at}))
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

  # If the research page is served from the DisputesController, this method is here.
  # If the controller action is moved to another controller, move this method to another class.
  def self.research_results(research_params)
    if research_params.present? && research_params['uri'].strip != ''
      url = research_params['uri'].gsub(/\r\n?/, "\n").strip # Remove all white spaces and newlines
      domain_of_url = DisputeEntry.domain_of(url)
      entries = entries_of_url(url)

      # BEGIN LOGIC TO CONSOLIDATE WLBL INFO TO UNIQUE URIS
      entries.each do |entry|
        entry.class.module_eval { attr_accessor :consolidated_wlbl_strings}
        entry.consolidated_wlbl_strings = entry.wbrs_list_type
      end

      unique_entries = entries.uniq{|e| e.hostlookup}
      duplicate_entries = entries - unique_entries

      duplicate_entries.each do |duplicate_entry|
        unique_entries.select{ |e| e.hostlookup == duplicate_entry.hostlookup}.map{ |e| e.consolidated_wlbl_strings << ", " + duplicate_entry.consolidated_wlbl_strings}
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

      if research_params['scope'] == "strict"
        unless entries.find{|entry| url == entry.uri}
          entries << DisputeEntry.new(uri: url)
        end
      end

      if research_params['scope'] == "broad" || entries.find{|entry| url == entry.uri}
        entries.each do |entry|
          is_ip_address = !!(entry.uri  =~ Resolv::IPv4::Regex)
          wbrs_stuff = Sbrs::ManualSbrs.get_wbrs_data({:url => entry.uri})
          wbrs_stuff_rulehits = Sbrs::ManualSbrs.get_rule_names_from_rulehits(wbrs_stuff)

          ip_addr = IPSocket.getaddress(entry.uri) rescue nil
          if ip_addr
            wbrs_stuff_ip = Sbrs::ManualSbrs.get_wbrs_data(url: ip_addr)
            wbrs_stuff_rulehits = wbrs_stuff_rulehits + Sbrs::ManualSbrs.get_rule_names_from_rulehits(wbrs_stuff_ip)
            wbrs_stuff_rulehits = wbrs_stuff_rulehits.uniq
          end

          entry.wbrs_score = wbrs_stuff["wbrs"]["score"]
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
            sbrs_stuff_rules = Sbrs::GetSbrs.get_sbrs_rules_for_ip(entry.uri)

            sbrs_stuff_rules.each do |rule_hit|
              new_rule_hit = DisputeRuleHit.new
              new_rule_hit.dispute_entry_id = entry.id
              new_rule_hit.name = rule_hit.strip
              new_rule_hit.rule_type = "SBRS"
              entry.dispute_rule_hits << new_rule_hit
            end

          end

        end

      end

      entries
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
end
