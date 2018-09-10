include ActionView::Helpers::DateHelper

class ComplaintEntry < ApplicationRecord
  has_paper_trail on: [:update], ignore: [:updated_at, :case_resolved_at, :case_assigned_at]

  belongs_to :complaint
  belongs_to :user, optional: true

  has_one :complaint_entry_screenshot
  has_one :complaint_entry_preload

  scope :assigned_count , -> {where(status:"ASSIGNED").count}
  scope :pending_count , -> {where(status:"PENDING").count}
  scope :new_count , -> {where(status:"NEW").count}
  scope :overdue_count , -> {where("created_at < ?",Time.now - 24.hours).where.not(status:"COMPLETED").count}

  RESOLVED = "RESOLVED"
  NEW = "NEW"
  PENDING = "PENDING"
  STATUS_COMPLETED = "COMPLETED"

  STATUS_RESOLVED_FIXED_FN = "FIXED FN"
  STATUS_RESOLVED_FIXED_FP = "FIXED FP"
  STATUS_RESOLVED_FIXED_UNCHANGED = "UNCHANGED"
  STATUS_RESOLVED_DUPLICATE = "DUPLICATE"


  def self.what_time_is_it(value)
    distance_of_time_in_words(value)
  end

  def self.is_ip?(ip)
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
    for_view
  end

  def location_url
    "http://#{subdomain+'.' if subdomain.present?}#{domain}#{path}"
  end

  def take_complaint(current_user)
    if user.nil? ||user.display_name == "Vrt Incoming"
      if status!="COMPLETED"
        self.update(user:current_user, status:"ASSIGNED", case_assigned_at: Time.now)
        complaint.set_status("ASSIGNED")
      else
        raise("Cannot take a completed complaint. How did this happen.")
      end
    else
      raise("Cannot take someone elses complaint.")
    end
  end
  def return_complaint(current_user)
    if self.user == current_user
      if !self.is_important
        if status!="COMPLETED"
          self.update(user: User.vrtincoming, status:"NEW")
          complaint.set_status("NEW")
        else
          raise("Cannot return complaint that has been completed.")
        end
      else
        raise("Cannot return complaint when status is pending.")
      end
    else
      if self.user.nil?
        raise("Cannot return a complaint that is not assigned")
      else
        raise("Cannot return someone elses complaint.")
      end
    end
  end

  def is_pending?
    "PENDING" == status
  end

  def uri_or_ip
    uri.present? ? uri : ip_address
  end

  def change_category(prefix,
                      categories_string,
                      entry_status,
                      comment,
                      resolution_comment,
                      current_user,
                      commit_pending)
    categories = categories_string&.split(',')
    ActiveRecord::Base.transaction do
      # If the prefix is a high telemetry value then the status needs to be set to PENDING
      if self.is_important
        if self.status == "PENDING"
          if commit_pending == "commit"
            # commit from pending of important case

            current_status = "COMPLETED"
            self.case_assigned_at ||= Time.now
            update(resolution:entry_status,
                   status:current_status,
                   internal_comment: comment,
                   resolution_comment: resolution_comment,
                   case_resolved_at: Time.now,
                   user:current_user)
            complaint.set_status(current_status)
            #this is where we should send off the category to the API
            if entry_status != "INVALID"
              commit_category(ip_or_uri: self.uri_or_ip,
                              categories_string: categories_string,
                              description: comment,
                              user: current_user.email)
            end
            cat_from_wbrs = self.set_current_category
            update(url_primary_category: cat_from_wbrs, category: cat_from_wbrs)
          else
            # dismiss from pending of important case

            current_status = "ASSIGNED"
            update(status:current_status,
                   internal_comment: comment,
                   resolution_comment: resolution_comment,
                   case_assigned_at: Time.now,
                   was_dismissed: true)
          end
        else
          # important not from pending

          current_status = "PENDING"
          update(resolution: entry_status,
                 url_primary_category: categories_string,
                 category: categories_string,
                 status:current_status,
                 internal_comment: comment,
                 resolution_comment: resolution_comment,
                 user:current_user)
        end
      else
        # not important case

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
        if entry_status != "INVALID"
          commit_category(ip_or_uri: self.uri_or_ip,
                          categories_string: categories_string,
                          description: comment,
                          user: current_user.email)
        end
        cat_from_wbrs = self.set_current_category
        update(url_primary_category: cat_from_wbrs, category: cat_from_wbrs)
      end
    end
  end

  def commit_category(ip_or_uri:, categories_string:, description:, user:)
    # Look for existing prefix
    existing_prefix = Wbrs::Prefix.where({urls: [ip_or_uri]})
    category_ids_array = Wbrs::Category.get_category_ids(categories_string.split(','))

    if existing_prefix.present?
      prefix_object = Wbrs::Prefix.new
      prefix_object.set_categories(category_ids_array, prefix_id: existing_prefix[0].prefix_id, user: user, description: description)
    else
      Wbrs::Prefix.create_from_url(url: ip_or_uri, categories: category_ids_array, user: user, description: description)
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

  def self.create_complaint_entry(complaint, ip_url, user = nil, status = NEW, categories = nil)
    begin
      new_complaint_entry = ComplaintEntry.new
      new_complaint_entry.complaint_id = complaint.id
      new_complaint_entry.status = status

      wbrs_stuff = Sbrs::ManualSbrs.get_wbrs_data({:url => ip_url})
      wbrs_score = wbrs_stuff["wbrs"]["score"]
      new_complaint_entry.wbrs_score = wbrs_score


      if is_ip?(ip_url)
        new_complaint_entry.ip_address = ip_url
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
      screenshot_data =  ""
      Timeout::timeout(max_wait_for_job) do
        screenshot_data = CapybaraSpider.low_capture("http://#{new_complaint_entry.hostlookup}")
      end
      ces = ComplaintEntryScreenshot.new
      ces.complaint_entry_id = new_complaint_entry.id
      ces.screenshot = Base64.decode64(screenshot_data)
      ces.save!
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
      when 'filter'
        filter_search(params, user: user)
      when 'contains'
        contains_search(params[:search])
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
  def self.filter_search(params, user:)
    case params[:filter_by]
      when "NEW"
        where(status:"NEW")
      when "COMPLETED"
        where(status:"COMPLETED")
      when "ACTIVE"
        where.not(status:"COMPLETED").where.not(status:"NEW")
      when "REVIEW"
        where(status: "PENDING")
      when "MY COMPLAINTS"
        where(user_id: user.id)
      when "MY OPEN COMPLAINTS"
        where(user_id: user.id).where.not(status: STATUS_COMPLETED)
      when "MY CLOSED COMPLAINTS"
        where(user_id: user.id, status:"COMPLETED")
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
        search_params[super_name] ||= {}
        search_params[super_name][sub_name] = criterion.value
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
    
    relation = where({})

    if params['submitted_newer'].present?
      relation =
          relation.joins(:complaint).where('complaints.created_at >= :submitted_newer', submitted_newer: params['submitted_newer'])
    end

    if params['submitted_older'].present?
      relation =
          relation.joins(:complaint).where('complaints.created_at < :submitted_older', submitted_older: params['submitted_older']+1)
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
          relation.joins(:complaint).where('complaints.updated_at >= :modified_newer', modified_newer: params['modified_newer'])
    end

    if params['modified_older'].present?
      relation =
          relation.joins(:complaint).where('complaints.updated_at < :modified_older', modified_older: params['modified_older']+1)
    end

    if params['tags'].present?
      relation = relation.joins(complaint: :complaint_tags).where('complaint_tags.name IN (?)', params['tags'])
    end


    company_name = nil
    customer_params = params.fetch('customer', {}).slice(*%w{name email company_name})
    customer_params = customer_params.select{|ignore_key, value| value.present?}
    if customer_params.any?
      if customer_params['company_name'].present?
        company_name = customer_params.delete('company_name')
        relation = relation.joins(complaint: [customer: :company])
      else
        relation = relation.joins(complaint: :customer)
      end

      customer_where = { customers: customer_params }
      if company_name.present?
        customer_where = { companies: {name: company_name} }
      end
      relation = relation.joins(complaint: [customer: :company]).where(customer_where)
    end

    entry_params = params.fetch('complaint_entries', {})

    if entry_params['complaint_id'] == [""]
      entry_params.delete('complaint_id')
    end

    entry_params = entry_params.select{|ignore_key, value| value.present?}
    if entry_params.any?
      complaint_entry_fields = entry_params.slice(*%w{complaint_id resolution status})
      ip_or_uri = entry_params['ip_or_uri']
      category = entry_params['category']

      relation = relation.group(:id)
      relation = relation.where(complaint_entry_fields) if complaint_entry_fields.present?

      if category.present?
        relation = relation.where('category like :category', category: "%#{category}%")
      end

      if ip_or_uri.present?
        ip_or_uri_clause = "ip_address = :ip_or_uri OR uri like :ip_or_uri_pattern OR domain like :ip_or_uri_pattern"
        relation = relation.where(ip_or_uri_clause, ip_or_uri: ip_or_uri, ip_or_uri_pattern: "%#{ip_or_uri}%")
      end
    end

    complaint_fields = params.to_h.slice(*%w{description channel})

    complaint_fields = complaint_fields.select{|ignore_key, value| value.present?}
    relation = relation.includes(:complaint).where(complaints: complaint_fields) if complaint_fields.present?

    # Save this search as a named search
    if params.present? && search_name.present?
      Dispute.save_named_search(search_name, params, user: user)
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
    prefix_results = Wbrs::Prefix.where({:urls => [self.hostlookup]})
    if prefix_results
      if prefix_results.first&.is_active == 1
        categories = prefix_results.map{ |result| result.descr}
        self.url_primary_category = categories.join(',')
        self.category = categories.join(',')
      else
        categories = nil
      end
    end
  rescue => except

    Rails.logger.warn "Populating categories from Wbrs failed."
    Rails.logger.warn except
    Rails.logger.warn except.backtrace.join("\n")

    ''
  end

  def current_category_data

    data = {}
    prefix_id = nil
    prefix_results = Wbrs::Prefix.where({:urls => [self.hostlookup]})

    prefix_results.each do |result|
      data[result.category] = {:is_active => result.is_active, :mnemonic => result.mnem, :category_id => result.category, :prefix_id => result.prefix_id}
      prefix_id = result.prefix_id
    end


    ###LOOK INTO:  CURRENTLY COMMENTED OUT UNTIL WE MEET UP WITH RULEAPI TEAM TO FIGURE OUT WHY HISTORY DOESN'T MATCH UP WITH CURRENT

    #audit_history = Wbrs::HistoryRecord.where({:prefix_id => prefix_id})
    #by_cat = {}
    #audit_history.each do |hist|

    #  if by_cat[hist.category_id].blank?
    #    by_cat[hist.category_id] = []
    #  end

    #  by_cat[hist.category_id] << hist
    #end

    #data.each do |key, value|
    #  data[key][:confidence] = by_cat[key].last.confidence
    #  data[key][:name] = by_cat[key].last.category.descr
    #  data[key][:long_description] = by_cat[key].last.category.desc_long
    #end

    ##Enter code to obtain certainty here, when it becomes available from the ruleapi guys
    ##in the meantime, dummy data
    data.each do |key, value|
      data[key][:certainty] = [{:source => "iwf", :source_category => "busi - Business and Industry", :source_certainty => '1000'}, {:source => "other_multi_eka", :source_category => "ngo - Non-government Organization", :source_certainty => '1000'}]
    end

    data
  end

  def historic_category_data

    prefix_id = nil
    prefix_results = Wbrs::Prefix.where({:urls => [self.hostlookup]})
    if prefix_results.present?
      prefix_id = prefix_results.first.prefix_id
    end
    if prefix_id.present?
      prefix_history = Wbrs::HistoryRecord.where({:prefix_id => prefix_id})
    else
      prefix_history = []
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

end
