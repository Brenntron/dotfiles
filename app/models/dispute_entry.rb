class DisputeEntry < ApplicationRecord
  has_paper_trail on: [:update], ignore: [:updated_at, :entry_type]
  belongs_to :dispute
  belongs_to :user
  has_many :dispute_rule_hits
  has_one  :dispute_entry_preload

  RESOLVED = "RESOLVED"
  NEW = "NEW"

  STATUS_RESOLVED_FIXED_FN = "FIXED FN"
  STATUS_RESOLVED_FIXED_FP = "FIXED FP"
  STATUS_RESOLVED_FIXED_UNCHANGED = "UNCHANGED"

  delegate :cvs_username, to: :dispute, allow_nil: true

  NEW = 'NEW'
  RESOLVED = 'RESOLVED'
  ASSIGNED = 'ASSIGNED'
  CLOSED = 'CLOSED'

  scope :open_entries, -> { where(status: NEW) }
  scope :closed_entries, -> { where(status: CLOSED) }
  scope :in_progress_entries, -> { where.not(status: [ NEW, CLOSED ]) }
  scope :my_team, ->(user) { joins(:dispute).where(disputes: {user_id: user.my_team}) }

  scope :resolved_date, -> (date_from_iso, date_to_iso) {
    date_from = Date.iso8601(date_from_iso)
    date_to = Date.iso8601(date_to_iso) + 1
    where(case_resolved_at: (date_from..date_to))
  }

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

  def find_xbrs
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

  def blacklist(reload: false)
    if reload == false
      if dispute_entry_preload.present? && dispute_entry_preload.wlbl.present?
        @blacklist = RepApi::Blacklist.load_from_prefetch(dispute_entry_preload.wlbl).first
        return @blacklist 
      end
    end
    @blacklist = nil if reload
    @blacklist ||= RepApi::Blacklist.where(entries: [ hostlookup ]).first
  end

  def classifications
    @classifications ||= blacklist&.classifications || []
  end

  def wbrs_list_type
    if dispute_entry_preload.present?
      @wbrs_list_type = dispute_entry_preload.wbrs_list_type
      return @wbrs_list_type if @wbrs_list_type.present?
      return nil
    end
    @wbrs_list_type ||= Wbrs::ManualWlbl.where(url: hostlookup).map{ |wlbl| wlbl.list_type }.join(',')
  end

  def wbrs_xlist
    if dispute_entry_preload.present? && dispute_entry_preload.crosslisted_urls.present?
      @wbrs_xlist = Wbrs::ManualWlbl.load_from_prefetch(dispute_entry_preload.crosslisted_urls)
      return @wbrs_xlist
    end
    @wbrs_xlist ||= Wbrs::ManualWlbl.where(url: hostlookup)
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
      references = Dispute.includes(:dispute_entries).where(:dispute_entries => {:ip_address => self.ip_address})
    else
      references = Dispute.includes(:dispute_entries).where(:dispute_entries => {:uri => self.uri})
    end
  end

  def last_submitted
    if self.referenced_tickets.count > 1
      last_submitted = referenced_tickets.last.created_at
    else
      last_submitted = "N/A"
    end
  end

  def update_from_field_data(values)
    attributes = values.inject({}) do |attrs, field_data|
      attrs[field_data['field']] = field_data['new']
      attrs
    end

    if attributes.has_key?('host')
      host = attributes.delete('host')
      if /\A(?<ip_address>\d+\.\d+\.\d+\.\d+)\z/ =~ host
        attributes['entry_type'] = 'IP'
        attributes['ip_address'] = ip_address
      else
        attributes['entry_type'] = 'URI/DOMAIN'
        attributes['hostname'] = host
      end
    end

    update(attributes.slice(*%w{entry_type ip_address hostname status}))
  end

  def self.update_from_field_data(field_data)
    field_data.each do |entry_id, values|
      entry = DisputeEntry.find(entry_id)
      entry.update_from_field_data(values)
    end
  end
end
