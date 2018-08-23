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

  def ti_status
    RESOLVED == status ? Dispute::TI_RESOLVED : Dispute::TI_NEW
  end

  def get_xbrs_value
    if dispute_entry_preload.present? && dispute_entry_preload.xbrs_history.present?
      return Xbrs::GetXbrs.load_from_prefetch(dispute_entry_preload.xbrs_history)
    end
    case
    when self.entry_type == "IP"
      Xbrs::GetXbrs.by_ip4(self.ip_address)
    when self.entry_type == "URI/DOMAIN"
      Xbrs::GetXbrs.by_domain(self.uri)
    else
      self.uri.blank? ? Xbrs::GetXbrs.by_ip4(self.ip_address) : Xbrs::GetXbrs.by_domain(self.uri)
    end
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
            RepApi::Blacklist.where(entries: [ hostlookup ]).first
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
    if dispute_entry_preload.present? && dispute_entry_preload.crosslisted_urls.present?
      @wbrs_xlist = Wbrs::ManualWlbl.load_from_prefetch(dispute_entry_preload.crosslisted_urls)
      return @wbrs_xlist
    end
    @wbrs_xlist ||= Wbrs::ManualWlbl.where({:url => hostlookup})
  rescue => except

    Rails.logger.warn "Populating xlist from Wbrs failed."
    Rails.logger.warn except
    Rails.logger.warn except.backtrace.join("\n")

    []
  end

  def virustotals
    #@virustotals = self.virustotal
    #return @virustotals if @virustotals.present?

    unless @virustotals
      if dispute_entry_preload.present? && dispute_entry_preload.virustotal.present?
        virustotal_data = Virustotal::GetVirustotal.load_from_prefetch(dispute_entry_preload.virustotal)
      else
        virustotal_data = Virustotal::GetVirustotal.by_domain(hostlookup)
      end
      #scans = Virustotal::GetVirustotal.by_domain(hostlookup)["scans"]
      scans = virustotal_data["scans"]
      cleandata = Array.new
      unless scans.nil?
        scans.each do |s|
          item = {:name => s[0], :result => s[1]["result"]}
          cleandata << item
        end
      end
      @virustotals = cleandata
    end
    @virustotals
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
    case
      # Per docs here: https://dashboard.umbrella.com/o/1755319/#overview
    when @umbrella[:status] == "-1"
      pretty_umbrella_status = "Malicious"
    when @umbrella[:status] == "1"
      pretty_umbrella_status = "Benign"
    end
    pretty_umbrella_status
  end

  def referenced_tickets
    is_ip_address = !!(hostlookup  =~ Resolv::IPv4::Regex)
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

  # If the research page is served from the DisputesController, this method is here.
  # If the controller action is moved to another controller, move this method to another class.
  def self.research_results(research_params)
    if research_params.present?
      url = research_params['uri'].gsub(/\s+/, "") # Remove all white spaces

      entries = Wbrs::ManualWlbl.where({:url => url}).map do |wlbl|
        DisputeEntry.new_from_wlbl(wlbl)
      end

      if research_params['scope'] == "strict"
        unless entries.find{|entry| url == entry.uri}
          entries << DisputeEntry.new(uri: url)
        end
      end

    entries.each do |entry|
      is_ip_address = !!(entry.uri  =~ Resolv::IPv4::Regex)
      wbrs_stuff = Sbrs::ManualSbrs.get_wbrs_data({:url => entry.uri})
      wbrs_stuff_rulehits = Sbrs::ManualSbrs.get_rule_names_from_rulehits(wbrs_stuff)

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


      entries
    else
      []
    end
  end
end
