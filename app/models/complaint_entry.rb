include ActionView::Helpers::DateHelper

class ComplaintEntry < ApplicationRecord
  has_paper_trail on: [:update], ignore: [:updated_at, :case_resolved_at, :case_assigned_at]

  belongs_to :complaint
  belongs_to :user, optional: true

  has_one :complaint_entry_screenshot
  has_one :complaint_entry_preload

  delegate :customer_name, :customer_company_name, to: :complaint, allow_nil: true, prefix: false
  delegate :cvs_username, :display_name, to: :user, allow_nil: true, prefix: true

  scope :open, -> { where.not(status: [STATUS_COMPLETED, RESOLVED]) }
  scope :closed, -> { where(status: [STATUS_COMPLETED, RESOLVED]) }
  scope :assigned_count , -> {where(status:"ASSIGNED").count}
  scope :pending_count , -> {where(status:"PENDING").count}
  scope :new_count , -> {where(status:"NEW").count}
  scope :overdue_count , -> {where("created_at < ?",Time.now - 24.hours).where.not(status:"COMPLETED").count}

  RESOLVED = "RESOLVED"
  NEW = "NEW"
  PENDING = "PENDING"
  STATUS_COMPLETED = "COMPLETED"
  STATUS_REOPENED = "REOPENED"
  STATUS_RESOLVED_FIXED_FN = "FIXED FN"
  STATUS_RESOLVED_FIXED_FP = "FIXED FP"
  STATUS_RESOLVED_FIXED_UNCHANGED = "UNCHANGED"
  STATUS_RESOLVED_FIXED_INVALID = "INVALID"
  STATUS_RESOLVED_DUPLICATE = "DUPLICATE"


  def self.what_time_is_it(value)
    distance_of_time_in_words(value)
  end

  def self.is_ip?(ip)
    ip = ip.scan(/(?:[0-9]{1,3}\.){3}[0-9]{1,3}/)[0] # When testing for IP address, don't include other parts of the url (e.g. 192.168.1.1/test.html is still a valid IP)
    !!IPAddr.new(ip) rescue false
  end

  def self.manipulate_changeset(changeset)
    altered_set = {}
    changeset.each do |field, (changed_from, changed_to)|
      if field == "user_id"
        user_from = User.where(id: changed_from).first&.cvs_username
        user_to = User.where(id: changed_to).first&.cvs_username
        altered_set["cvs_username"] = [user_from, user_to]
      end
    end
    altered_set.merge(changeset)
  end

  def compose_versions
    for_view = {}
    versions.each do |version|
      whodunnit = {whodunnit: User.where(id: version.whodunnit).first&.cvs_username}
      set_with_usernames = ComplaintEntry.manipulate_changeset(version.changeset)
      for_view[version.created_at] = set_with_usernames.merge(whodunnit)
    end

    for_view.sort_by {|key, val| key}.reverse
  end

  def location_url
    "http://#{subdomain+'.' if subdomain.present?}#{domain}#{path}"
  end

  def take_complaint(current_user)
    if user.nil? || user.display_name == "Vrt Incoming"
      if status != "COMPLETED"
        self.update(user:current_user, status:"ASSIGNED", case_assigned_at: Time.now)
        complaint.set_status("ASSIGNED")
      else
        return("Already completed")
      end
    else
      return("Someone elses complaint")
    end
    return("Complaint taken")
  end
  def return_complaint
    if self.user != User.where(display_name: 'Vrt Incoming').first
      if !self.is_important
        if status!="COMPLETED"
          self.update(user: User.vrtincoming, status:"NEW")
          complaint.set_status("NEW")
        else
          return("Already completed")
        end
      elsif self.is_important && self.status != "PENDING"
        self.update(user: User.vrtincoming, status:"NEW")
        complaint.set_status("NEW")
      else
        return("Status is pending")
      end
    else
      return("Not yet assigned")
    end
    return("Complaint returned")
  end

  def is_pending?
    "PENDING" == status
  end

  def uri_or_ip
    uri.present? ? uri : ip_address
  end

  def change_category(prefix,
                      categories_string,
                      category_names_string,
                      entry_status,
                      comment,
                      resolution_comment,
                      current_user,
                      commit_pending)
    ActiveRecord::Base.transaction do
      # If the prefix is a high telemetry value then the status needs to be set to PENDING
      if self.is_important && entry_status != Complaint::RESOLUTION_UNCHANGED
        if self.status == "PENDING"
          if commit_pending == "commit"
            # commit from pending of important case

            current_status = "COMPLETED"
            self.case_assigned_at ||= Time.now
            update(status:current_status,
                   internal_comment: comment,
                   resolution_comment: resolution_comment,
                   case_resolved_at: Time.now,
                   user:current_user)
            complaint.set_status(current_status)
            #this is where we should send off the category to the API
            if self.resolution != STATUS_RESOLVED_FIXED_INVALID && !categories_string.blank?
              commit_category(ip_or_uri: prefix,
                              categories_string: categories_string,
                              description: comment,
                              user: current_user.email,
                              casenumber: self.complaint.id)
            end
            cat_from_wbrs = self.set_current_category
            update(url_primary_category: cat_from_wbrs, category: cat_from_wbrs)
          else
            # dismiss from pending of important case

            current_status = "ASSIGNED"
            update(status:current_status,
                   url_primary_category: nil,
                   internal_comment: comment,
                   resolution_comment: resolution_comment,
                   case_assigned_at: Time.now,
                   was_dismissed: true)
          end
        else
          # important not from pending

          current_status = "PENDING"
          update(resolution: entry_status,
                 url_primary_category: category_names_string,
                 category: categories_string,
                 status:current_status,
                 internal_comment: comment,
                 resolution_comment: resolution_comment,
                 user:current_user)
        end
      else
        # not important case or resolution is "unchanged"
        current_status = "COMPLETED"
        self.case_assigned_at ||= Time.now
        update(resolution: entry_status,
               url_primary_category: categories_string,
               category: categories_string,
               status: current_status,
               internal_comment: comment,
               resolution_comment: resolution_comment,
               case_resolved_at: Time.now,user:current_user)
        complaint.set_status(current_status)
        #this is where we should send off the category to the API
        if ![STATUS_RESOLVED_FIXED_INVALID,STATUS_RESOLVED_FIXED_UNCHANGED].include?(entry_status) && !categories_string.blank?
          commit_category(ip_or_uri: prefix,
                          categories_string: categories_string,
                          description: comment,
                          user: current_user.email,
                          casenumber: self.complaint.id )
        end
        cat_from_wbrs = self.set_current_category
        update(url_primary_category: cat_from_wbrs, category: cat_from_wbrs)
      end
    end

  end

  def commit_category(ip_or_uri:, categories_string:, description:, user:, casenumber: nil)
    # Look for existing prefix
    is_ip_address = !!(ip_or_uri  =~ Resolv::IPv4::Regex)

    url_parts = Complaint.parse_url(ip_or_uri)
    existing_prefixes = Wbrs::Prefix.where({urls: [ip_or_uri]})
    existing_prefix = nil
    if existing_prefixes.present? && !is_ip_address
      existing_prefixes.each do |prefix_found|
        if prefix_found.subdomain == url_parts[:subdomain]
          if prefix_found.path == url_parts[:path]
            existing_prefix = prefix_found
          end
        end
      end
    end

    if is_ip_address
      existing_prefixes.each do |prefix_found|
        if prefix_found.domain == ip_or_uri
          existing_prefix = prefix_found
        end
      end
    end

    category_ids_array = categories_string.split(',').map {|cat| cat.to_i}

    if description.present? && casenumber.present?
      description = description + "--Case Number: #{casenumber} User: #{user}"
    end
    if existing_prefix.present?
      prefix_object = Wbrs::Prefix.new
      prefix_object.set_categories(category_ids_array, prefix_id: existing_prefix.prefix_id, user: user, description: description)
    else
      Wbrs::Prefix.create_from_url(url: ip_or_uri, categories: category_ids_array, user: user, description: description)
    end
  end

  def inherit_categories(ip_or_uri:, description:, user:, casenumber: nil)
    if ip_or_uri != self.domain
      parsed_uri = Complaint.parse_url(ip_or_uri)
      master_domain = parsed_uri[:domain]

      existing_prefixes = Wbrs::Prefix.where({urls: [ip_or_uri]})

      existing_prefix = nil

      if existing_prefixes.present?
        existing_prefix = existing_prefixes.find { |existing_prefix| existing_prefix.subdomain == parsed_uri[:subdomain] && existing_prefix.path == parsed_uri[:path] }
      end

      if description.present? && casenumber.present?
        description = description + "--Case Number: #{casenumber} User: #{user}"
      end

      # Get the categories from the master domain
      category_data = ComplaintEntry.get_category_data(master_domain)
      category_ids = category_data[:category_ids]
      category_names = category_data[:category_names]

      # Inherit categories from the master domain
      if existing_prefix.present?
        prefix_object = Wbrs::Prefix.new
        prefix_object.set_categories(category_ids, user: user, description: description, prefix_id: existing_prefix.prefix_id)
      else
        Wbrs::Prefix.create_from_url(url: ip_or_uri, categories: category_ids, user: user, description: description)
      end

      self.update(url_primary_category: category_names[0])
    elsif ip_or_uri == self.domain
      raise ('Cannot inherit categories on master domain')
    end
  end

  def self.self_importance(ip_url)
    begin
      Wbrs::TopUrl.check_urls([ip_url]).first&.is_important
    rescue Exception => e
      Rails.logger.warn "Failed while getting importance."
      Rails.logger.warn e
      Rails.logger.warn e&.backtrace&.join("\n")
    end
  end

  def self.create_wbnp_complaint_entry(complaint, ip_url, url_parts, user = nil, status = NEW, categories = nil)

    new_complaint_entry = ComplaintEntry.new
    new_complaint_entry.complaint_id = complaint.id
    new_complaint_entry.status = status

    begin
      wbrs_stuff = Sbrs::ManualSbrs.get_wbrs_data({:url => URI.escape(ip_url)})
      wbrs_score = wbrs_stuff["wbrs"]["score"]
      new_complaint_entry.wbrs_score = wbrs_score
    rescue
      #do nothing continue with saving the entry
    end

    if is_ip?(ip_url)
      ip_url.chomp!("/")
      ip_network = ip_url.scan(/(?:[0-9]{1,3}\.){3}[0-9]{1,3}/)[0]
      ip_path = ip_url.sub(ip_network, '')
      new_complaint_entry.ip_address = ip_network
      new_complaint_entry.path = ip_path
      new_complaint_entry.entry_type = "IP"

    else
      new_complaint_entry.uri = ip_url
      new_complaint_entry.entry_type = "URI/DOMAIN"
      new_complaint_entry.subdomain = url_parts["subdomain"]
      new_complaint_entry.domain = url_parts["domain"]
      new_complaint_entry.path = url_parts["path"]
    end
    #lets query the top url API endpoint to determine if this is an important site or not
    # but you better believe i dont trust this API so we have some checks to ensure the entry gets created
    begin
      importance = self_importance(ip_url)
      new_complaint_entry.is_important = importance if importance
    rescue
      #do nothing keep building entry
    end
    new_complaint_entry.user = user
    new_complaint_entry.case_assigned_at ||= Time.now if user && user.display_name != "Vrt Incoming"

    if status == PENDING # occurs when attempt to categorized a Top URl without a complaint
      new_complaint_entry.url_primary_category = categories
      new_complaint_entry.category = categories
    else
      current_category = new_complaint_entry.set_current_category
      new_complaint_entry.url_primary_category = current_category
      new_complaint_entry.category = current_category
    end

    new_complaint_entry.save

    ComplaintEntryPreload.generate_preload_from_complaint_entry(new_complaint_entry)

    delay.capture_screenshot(new_complaint_entry.hostlookup, new_complaint_entry.id)
  end

  class << self
    def capture_screenshot(uri, complaint_entry_id)
      max_wait_for_job = 15 #seconds
      begin
        screenshot_data =  ""
        Timeout::timeout(max_wait_for_job) do
          screenshot_data = CapybaraSpider.low_capture("#{uri}")
        end
        ces = ComplaintEntryScreenshot.new
        ces.complaint_entry_id = complaint_entry_id
        ces.screenshot = Base64.decode64(screenshot_data)
        ces.save!
      rescue Timeout::Error => e
        #couldnt complete in time
        Rails.logger.error( "#{e} --- Timed out waiting for screenshot for #{uri} to finish")
        ces = ComplaintEntryScreenshot.new
        ces.error_message = e.message
        ces.complaint_entry_id = complaint_entry_id
        open("app/assets/images/failed_screenshot.jpg") do |f|
          ces.screenshot = f.read
        end
        ces.save!
      rescue Exception => e
        Rails.logger.error("#{e.message}")
        #do nothing, it was worth a try. kittens are sad now
        ces = ComplaintEntryScreenshot.new
        ces.error_message = e.message
        ces.complaint_entry_id = complaint_entry_id
        open("app/assets/images/failed_screenshot.jpg") do |f|
          ces.screenshot = f.read
        end
        ces.save!
      end

    end
    handle_asynchronously :capture_screenshot
  end


  def self.create_complaint_entry(complaint, ip_url, user = nil, status = NEW, categories = nil)
    begin
      new_complaint_entry = ComplaintEntry.new
      new_complaint_entry.complaint_id = complaint.id
      new_complaint_entry.status = status

      wbrs_stuff = Sbrs::ManualSbrs.get_wbrs_data({:url => URI.escape(ip_url)})
      wbrs_score = wbrs_stuff["wbrs"]["score"]
      new_complaint_entry.wbrs_score = wbrs_score


      if is_ip?(ip_url)
        ip_url.chomp!("/")
        ip_network = ip_url.scan(/(?:[0-9]{1,3}\.){3}[0-9]{1,3}/)[0]
        ip_path = ip_url.sub(ip_network, '')
        new_complaint_entry.ip_address = ip_network
        new_complaint_entry.path = ip_path
        new_complaint_entry.entry_type = "IP"
      else
        url_parts = Complaint.parse_url(ip_url)
        new_complaint_entry.uri = ip_url
        new_complaint_entry.entry_type = "URI/DOMAIN"
        new_complaint_entry.subdomain = url_parts[:subdomain]
        new_complaint_entry.domain = url_parts[:domain]
        new_complaint_entry.path = url_parts[:path]
      end
      #lets query the top url API endpoint to determine if this is an important site or not
      # but you better believe i dont trust this API so we have some checks to ensure the entry gets created
      importance = self_importance(ip_url)
      new_complaint_entry.is_important = importance if importance
      new_complaint_entry.user = user
      new_complaint_entry.case_assigned_at ||= Time.now if user && user.display_name != "Vrt Incoming"

      if status == PENDING # occurs when attempt to categorized a Top URl without a complaint
        new_complaint_entry.url_primary_category = categories
        new_complaint_entry.category = categories
      else
        current_category = new_complaint_entry.set_current_category
        new_complaint_entry.url_primary_category = current_category
        new_complaint_entry.category = current_category
      end

      new_complaint_entry.save

    rescue Exception => e
      raise Exception.new("{ComplaintEntry creation error: {content: #{ip_url},error:#{e}}}")
    end

    ComplaintEntryPreload.generate_preload_from_complaint_entry(new_complaint_entry)
    max_wait_for_job = 15 #seconds
    begin
      #this is where screen grabs happen.
      screenshot_entry = ComplaintEntryScreenshot.create!(complaint_entry_id:new_complaint_entry.id)
      screenshot_entry.grab_screenshot
    rescue Timeout::Error => e
      #couldnt complete in time
      Rails.logger.error( "#{e} --- Timed out waiting for screenshot for #{new_complaint_entry.hostlookup} to finish")
      ces = ComplaintEntryScreenshot.new
      ces.error_message = e.message
      ces.complaint_entry_id = new_complaint_entry.id
      open("app/assets/images/failed_screenshot.jpg") do |f|
        ces.screenshot = f.read
      end
      ces.save!
    rescue Exception => e
      Rails.logger.error("#{e.message}")
      #do nothing, it was worth a try. kittens are sad now
      ces = ComplaintEntryScreenshot.new
      ces.error_message = e.message
      ces.complaint_entry_id = new_complaint_entry.id
      open("app/assets/images/failed_screenshot.jpg") do |f|
        ces.screenshot = f.read
      end
      ces.save!
    end
  end

  # Searches in a variety of ways.
  # advanced -- search by supplied field.
  # named -- call a saved search.
  # standard -- use a pre-defined search.
  # contains -- search many fields where supplied value is contained in the field.
  # nil -- all records.
  # @param [String] search_type variety of search
  # @param [ActionController::Parameters] params supplied fields and values for search.
  # @param [String] search_name name of saved search.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.robust_search(search_type, search_name: nil, params: nil, user:)
    case search_type
      when 'advanced'
        advanced_search(params, search_name: search_name, user: user)
      when 'named'
        named_search(search_name, user: user)
      when 'standard'
        standard_search(search_name, user: user)
      when 'contains'
        contains_search(params[:value])
      else
        where({})
    end
  end

  def self.get_search_type(search_params)
    if search_params['search']
      'contains'
    elsif search_params['filter_by']
      'filter'
    elsif search_params['search_type'] == 'named'
      'named'
    elsif search_params['search_type']
      'advanced'
    else
      nil
    end
  end

  # Searches many fields in the record for values containing a given value.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.contains_search(value)
    complaint_entry_fields = %w{complaint_id subdomain domain path url_primary_category
                        complaint_entries.resolution complaint_entries.internal_comment complaint_entries.status uri ip_address category}
    complaint_entry_where = complaint_entry_fields.map{|field| "#{field} like :pattern"}.join(' or ')

    customer_where = %w{name email}.map{|field| "customers.#{field} like :pattern"}.join(' or ')
    company_where = 'companies.name like :pattern'

    where_str = "#{complaint_entry_where} or #{customer_where} or #{company_where}"
    left_joins(complaint: [customer: :company]).where(where_str, pattern: "%#{value}%")
  end

  # Searches specific to quick generic button filters.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.standard_search(search_name, user:)
    case search_name
      when "NEW"
        where(status:"NEW")
      when "COMPLETED"
        closed
      when "ACTIVE"
        open.where.not(status:"NEW")
      when "REVIEW"
        where(status: "PENDING")
      when "MY COMPLAINTS"
        where(user_id: user.id)
      when "MY OPEN COMPLAINTS"
        open.where(user_id: user.id)
      when "MY CLOSED COMPLAINTS"
        closed.where(user_id: user.id)
      when "ALL"
        all
      else
        all
    end
  end


  # Searched based on saved search.
  # @param [String] search_name the name of the saved search.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.named_search(search_name, user:)
    named_search = user.named_searches.where(name: search_name).first
    raise "No search named '#{search_name}' found." unless named_search
    search_params = named_search.named_search_criteria.inject({}) do |search_params, criterion|
      if /\A(?<super_name>[^~]*)~(?<sub_name>[^~]*)\z/ =~ criterion.field_name
        if criterion.field_name == 'complaint_entries~complaint_id'
          search_params[super_name] ||= {}
          search_params[super_name][sub_name] = YAML::load(criterion.value)
        else
          search_params[super_name] ||= {}
          search_params[super_name][sub_name] = criterion.value
        end
      else
        search_params[criterion.field_name] = criterion.value
      end
      search_params
    end
    advanced_search(search_params, search_name: nil, user: user)
  end

  # Searches based on supplied fields and values.
  # Optionally takes a name to save this search as a saved search.
  # @param [ActionController::Parameters] params supplied fields and values for search.
  # @param [String] search_name name to save this search as a saved search.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.advanced_search(params, search_name:, user:)

    present_params = params.select{|ignore_key, value| value.present?}

    simple_params = present_params.slice(*%w{id complaint_id resolution status})
    relation = where(simple_params)

    if params['submitted_newer'].present?
      relation =
          relation.joins(:complaint).where('complaints.created_at >= :submitted_newer',
                                           submitted_newer: params['submitted_newer'])
    end

    if params['submitted_older'].present?
      relation =
          relation.joins(:complaint).where('complaints.created_at < DATE_ADD(:submitted_older, INTERVAL 1 DAY)',
                                           submitted_older: params['submitted_older'])
    end

    if params['age_newer'].present?
      seconds_ago = Dispute.age_to_seconds(params['age_newer'])
      unless 0 == seconds_ago
        age_newer_cutoff = Time.now - seconds_ago
        relation =
            relation.joins(:complaint).where('complaints.created_at >= :submitted_newer', submitted_newer: age_newer_cutoff)

      end
    end

    if params['age_older'].present?
      seconds_ago = Dispute.age_to_seconds(params['age_older'])
      unless 0 == seconds_ago
        age_older_cutoff = Time.now - seconds_ago
        relation =
            relation.joins(:complaint).where('complaints.created_at < :submitted_older', submitted_older: age_older_cutoff)
      end
    end

    if params['modified_newer'].present?
      relation =
          relation.joins(:complaint).where('complaints.updated_at >= :modified_newer',
                                           modified_newer: params['modified_newer'])
    end

    if params['modified_older'].present?
      relation = relation.joins(:complaint).where('complaints.updated_at < DATE_ADD(:modified_older, INTERVAL 1 DAY)',
                                                  modified_older: params['modified_older'])
    end

    if params['tags'].present?
      relation = relation.joins(complaint: :complaint_tags).where(complaint_tags: {name: params['tags']})
    end

    customer_params = present_params.slice(*%w{customer_name customer_email company_name})
    unless customer_params.empty?
      company_name = nil
      if customer_params['company_name'].present?
        company_name = customer_params.delete('company_name')
        relation = relation.joins(complaint: {customer: :company})
      else
        relation = relation.joins(complaint: :customer)
      end

      if customer_params['customer_name'].present?
        relation = relation.where(customers: {name: customer_params['customer_name']})
      end

      if customer_params['customer_email'].present?
        relation = relation.where(customers: {email: customer_params['customer_email']})
      end

      if company_name.present?
        relation = relation.where(companies: {name: company_name})
      end
    end

    #relation = relation.group(:id)

    category = present_params['category']
    if category.present?
      relation = relation.where('category like :category', category: "%#{category}%")
    end

    ip_or_uri = present_params['ip_or_uri']
    if ip_or_uri.present?
      ip_or_uri_clause = "ip_address = :ip_or_uri OR uri like :ip_or_uri_pattern OR domain like :ip_or_uri_pattern"
      relation = relation.where(ip_or_uri_clause, ip_or_uri: ip_or_uri, ip_or_uri_pattern: "%#{ip_or_uri}%")
    end

    complaint_fields = present_params.to_h.slice(*%w{description channel})
    if complaint_fields.present?
      relation = relation.includes(:complaint).where(complaints: complaint_fields)
    end

    # Save this search as a named search
    if present_params.present? && search_name.present?
      Dispute.save_named_search(search_name, params, user: user, project_type: 'Complaint')
    end
    relation
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

  ####RULEUI RULEAPI METHODS
  #

  def set_current_category
    category_list = []
    prefix_results = Wbrs::Prefix.where({:urls => [URI.escape(self.hostlookup)]})
    if prefix_results
      if prefix_results.first&.is_active == 1

        categories = prefix_results.find_all {|result| result.path == self.path}
        categories.each do |cat|
          if cat.subdomain == self.subdomain
            category_list << Wbrs::Category.find(cat.category_id).descr
          end
        end

        self.url_primary_category = category_list.uniq.join(',')
        self.category = category_list.uniq.join(',')
      else
        categories = nil
      end
    end

    category_list.uniq.join(',')
  rescue => except

    Rails.logger.warn "Populating categories from Wbrs failed."
    Rails.logger.warn except
    Rails.logger.warn except.backtrace.join("\n")

    ''
  end

  def self.get_category_data(uri)
    prefix_results = Wbrs::Prefix.where({:urls => [uri]})

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

    category_ids = final_results.first.categories.sort_by(&:confidence).map {|category| category.category_id}
    category_names = final_results.first.categories.sort_by(&:confidence).map {|category| category.descr}

    {category_ids: category_ids, category_names: category_names}
  end

  def get_category_names_from_master
    prefix_results = Wbrs::Prefix.where({:urls => [self.domain]})

    if self.entry_type == 'URI/DOMAIN'
      parsed_uri = Complaint.parse_url(uri)

      return [] unless prefix_results

      parsed_uri['path'] = '' unless parsed_uri['path'].present?
      parsed_uri['subdomain'] = '' unless parsed_uri['subdomain'].present?

      categories = []

      prefix_results.each do |prefix_result|
        if ((prefix_result.subdomain == parsed_uri['subdomain']) || (parsed_uri['subdomain'] == 'www')) && prefix_result.path == parsed_uri['path']
          categories << prefix_result
        end
      end

      if categories.any?
        categories = categories.first.categories.map {|category| category.descr}
      end

      categories
    elsif self.entry_type == 'IP'
      raise ("Cannot inherit categories for IP entries.")
    end
  end

  def current_category_data

    prefix_results = Wbrs::Prefix.where({:urls => [DisputeEntry.domain_of_with_path(self.hostlookup)]})
    return {} unless prefix_results
    domain_of = DisputeEntry.domain_of_with_path(self.hostlookup)
    certainty_on_urls = Wbrs::Prefix.get_certainty_sources_for_urls([domain_of])

    final_results = []
    categories = prefix_results.find_all {|result| result.path == self.path}
    categories.each do |cat|
      if (cat.subdomain == self.subdomain) || (self.subdomain == 'www')
        final_results << cat
      end
    end

    final_current_categories = {}

    final_results.each do |result|
      current_categories = result.categories
      category_certainty = {}
      certainty_on_urls.each do |cert_url, info|

        info.each do |cert_info|
          if cert_info['subdomain'] == result.subdomain && cert_info['path'] == result.path
            if category_certainty[(cert_info['category_id'].to_i - 1000)].blank?
              category_certainty[(cert_info['category_id'].to_i - 1000)] = []
            end
            #category_certainty[(cert_info['category_id'].to_i - 1000)] = {:category_id => cert_info['category_id'], :certainty => cert_info['certainty'], :source_mnemonic => cert_info['source_mnemonic'], :source_description => cert_info['source_description']}
            category_certainty[(cert_info['category_id'].to_i - 1000)] << {:category_id => (cert_info['category_id'].to_i - 1000), :certainty => cert_info['certainty'], :source_mnemonic => cert_info['source_mnemonic'], :source_description => cert_info['source_description']}
          end
        end
      end

      final_current_categories = current_categories
      final_current_categories = final_current_categories.inject({}) do |data, category|
        top_certainty = ""
        if category_certainty[category.category_id].present?
          top_certainty = category_certainty[category.category_id].first[:certainty]
          source = category_certainty[category.category_id].first[:source_description]

        end
        data[category.confidence] = {
            category_id: category.category_id,
            desc_long: category.desc_long,
            descr: category.descr,
            mnem: category.mnem,
            is_active: category.is_active,
            confidence: category.confidence,
            top_certainty: top_certainty,
            certainties: category_certainty[category.category_id]
        }
        data
      end
    end

    final_current_categories

    #current_categories = prefix.categories

    #current_categories.inject({}) do |data, category|
    #  data[category.category_id] = {
    #      category_id: category.category_id,
    #      desc_long: category.desc_long,
    #      descr: category.descr,
    #      mnem: category.mnem,
    #      is_active: category.is_active,
    #      confidence: category.confidence
    #  }
    #  data
    #end
  end

  def self.get_category(uri_ip)
    prefix = Wbrs::Prefix.where({:urls => [uri_ip]})&.first
    return {} unless prefix

    current_categories = prefix.categories

    name = current_categories[0].descr

    name
  end

  def historic_category_data

    prefix_history = []
    prefixes = Wbrs::Prefix.where({:urls => [URI.escape(self.hostlookup)]})
    prefixes.each do |prefix|
      if prefix.subdomain == self.subdomain && prefix.path == self.path
        prefix_id = prefix.prefix_id
        response = Wbrs::HistoryRecord.where({:prefix_id => prefix_id}).sort_by {|history| DateTime.parse(history.time)}.reverse
        response.each do |resp|
          prefix_history << resp
        end
      end
    end

    prefix_history
  end

  def history_category_data_with_preload_save

    prefix_id = nil
    prefix_results = Wbrs::Prefix.where({:urls => [URI.escape(self.hostlookup)]})

    complaint_entry_preload = ComplaintEntryPreload.where(complaint_entry_id: self.id).first

    if prefix_results.present?
      prefix_id = prefix_results.first.prefix_id
    end

    if prefix_id.present?
      prefix_history = Wbrs::HistoryRecord.where({:prefix_id => prefix_id}).sort_by {|history| history.time}.reverse
      if complaint_entry_preload.present?
        complaint_entry_preload.historic_category_information ||= prefix_history.to_json
        complaint_entry_preload.save
      else
        ComplaintEntryPreload.create(complaint_entry_id: self.id, historic_category_information: prefix_history.to_json)
      end
    else
      prefix_history = []
      if complaint_entry_preload.present?
        complaint_entry_preload.historic_category_information ||= 'DATA ERROR'
      else
        ComplaintEntryPreload.create(complaint_entry_id: self.id, historic_category_information: 'DATA ERROR')
      end
    end

    prefix_history
  end

  def capture_screenshot
    CapybaraSpider.capture(self.location_url) do |capture|
      if complaint_entry_screenshot
        complaint_entry_screenshot.destroy
      end
      my_screenshot = build_complaint_entry_screenshot
      my_screenshot.screenshot = capture.read
      my_screenshot.save!
    end
  end

  def self.complaint_entry_preload
    ComplaintEntryPreload.where(complaint_entry_id: self.id).last
  end

  def self.current_category_information
    self.complaint_entry_preload.current_category_information
  end

  def update_uri(uri)
    if self&.entry_type == 'IP'
      return {status: 'ip'}
    elsif entry_type == 'URI/DOMAIN' || entry_type.nil?
      parsed_uri = Complaint.parse_url(uri)

      self.domain = parsed_uri[:domain]
      self.subdomain = parsed_uri[:subdomain]
      self.path = parsed_uri[:path]

      if self.subdomain.present?
        self.uri = subdomain + '.' + domain
      else
        self.uri = uri
      end

      ComplaintEntryPreload.generate_preload_from_complaint_entry(self)

      if save!
        {status: 'success'}
      end
    end
  end

  def reopen
    if self&.status != STATUS_COMPLETED
      return false
    end

    self.status = STATUS_REOPENED
    self.resolution = nil
    self.resolution_comment = self.resolution_comment + "<br />" + " --This dispute has been re-opened."
    if save
      if self.complaint.status == Complaint::COMPLETED
        self.complaint.status = Complaint::REOPENED
        self.complaint.save
      end

      message = Bridge::ComplaintUpdateStatusEvent.new
      message.post_complaint(self.complaint)

      return true
    else
      return false
    end
  end
end
