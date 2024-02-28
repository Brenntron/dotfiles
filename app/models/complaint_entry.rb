include ActionView::Helpers::DateHelper

class ComplaintEntry < ApplicationRecord
  has_paper_trail on: [:update], ignore: [:updated_at, :case_resolved_at, :case_assigned_at]

  before_update :update_duplicates

  after_create :check_and_process_duplicate

  belongs_to :canonical, class_name: "ComplaintEntry", optional: true

  has_many :duplicate_entries, class_name: "ComplaintEntry", foreign_key: 'canonical_id'
  has_many :abuse_records

  belongs_to :complaint
  belongs_to :user, optional: true
  belongs_to :reviewer, class_name: 'User', optional: true
  belongs_to :second_reviewer, class_name: 'User', optional: true
  belongs_to :product_platform, :class_name => "Platform", :foreign_key => "platform_id", optional: true
  has_one :complaint_entry_screenshot
  has_one :complaint_entry_preload

  delegate :customer_name, :customer_company_name, to: :complaint, allow_nil: true, prefix: false
  delegate :cvs_username, :display_name, to: :user, allow_nil: true, prefix: true

  scope :open, -> { where.not(status: [STATUS_COMPLETED, RESOLVED]) }
  scope :open_tickets, -> { where.not(status: [STATUS_COMPLETED, RESOLVED]) }
  scope :closed, -> { where(status: [STATUS_COMPLETED, RESOLVED]) }
  scope :new_entries, -> { where(status: [NEW]) }
  scope :assigned_count , -> {where(status:"ASSIGNED").count}
  scope :pending_count , -> {where(status:"PENDING").count}
  scope :new_count , -> {where(status:"NEW").count}
  scope :overdue_count , -> {where("created_at < ?",Time.now - 24.hours).where.not(status:"COMPLETED").count}

  RESOLVED = "RESOLVED"
  NEW = "NEW"
  PENDING = "PENDING"
  ASSIGNED = "ASSIGNED"
  STATUS_COMPLETED = "COMPLETED"
  STATUS_REOPENED = "REOPENED"
  STATUS_RESOLVED_FIXED_FN = "FIXED FN"
  STATUS_RESOLVED_FIXED_FP = "FIXED FP"
  STATUS_RESOLVED_FIXED_UNCHANGED = "UNCHANGED"
  STATUS_RESOLVED_FIXED_INVALID = "INVALID"
  STATUS_RESOLVED_DUPLICATE = "DUPLICATE"

  #this is a temporary status until R-ACE has made it across all of ac-e
  STATUS_WEBCAT_DUPLICATE = "WC-DUPLICATE"

  validates_length_of :resolution_comment, maximum: 2000, allow_blank: true

  def find_duplicates
    uri_or_ip = self.hostlookup
    #support for ipv6 carried over from work done in WEB-11015 while this was being developed
    #is_ip_address = !!(uri_or_ip  =~ Resolv::IPv4::Regex)
    is_ip_address = !!(uri_or_ip =~ Resolv::IPv4::Regex || uri_or_ip =~ Resolv::IPv6::Regex)
    
    if is_ip_address
      ComplaintEntry.open_tickets.where(:ip_address => uri_or_ip).where("id <> #{self.id}").first
    else
      ComplaintEntry.open_tickets.where(:uri => uri_or_ip).where("id <> #{self.id}").first
    end

  end

  def convert_to_duplicate(canonical_entry)
    self.canonical_id = canonical_entry.id
    self.status = STATUS_WEBCAT_DUPLICATE
    self.save
  end

  def check_and_process_duplicate
    canonical = find_duplicates

    if canonical.present?
      convert_to_duplicate(canonical)
    end
  end

  def update_duplicates

    self.duplicate_entries.each do |dupe|

      dupe.status = self.status
      dupe.resolution = self.resolution
      dupe.resolution_comment = self.resolution_comment
      dupe.save
      message = Bridge::ComplaintUpdateStatusEvent.new
      message.post_complaint(self.complaint)
    end
  end

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

  def self.current_category_data_for_uri(uri)
    prefix = Wbrs::Prefix.where({:urls => [Addressable::URI.escape(uri)]})&.first
    return {} unless prefix

    current_categories = prefix.categories
    current_categories.inject({}) do |data, category|
      data[category.category_id] = {
          category_id: category.category_id,
          desc_long: category.desc_long,
          descr: category.descr,
          mnem: category.mnem,
          is_active: category.is_active,
          confidence: category.confidence }
      data
    end
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

  def take_complaint(current_user, assignment_type)
    error_messages = {
        'assignee' => 'Currently assigned to someone else',
        'reviewer' => 'Someone else is currently reviewing',
        'second_reviewer' => 'Someone else is currently reviewing'
    }

    return("Already completed") if status == "COMPLETED"

    if assignment_type == 'assignee' && [reviewer&.id, second_reviewer&.id].include?(current_user.id)
      return('A Reviewer cannot also be the Assignee.')
    elsif assignment_type == 'assignee' && (self.user.nil? || self.user.display_name == 'Vrt Incoming')
      update(user: current_user, status: "ASSIGNED", case_assigned_at: Time.now)
      complaint.set_status("ASSIGNED")
    elsif ['second_reviewer', 'reviewer'].include?(assignment_type) && self.user.id == current_user.id
      return('The Assignee cannot also be a Reviewer.')
    elsif assignment_type == 'reviewer' && reviewer.nil? && second_reviewer&.id == self.user.id
      return('The Reviewer cannot also be the Second Reviewer.')
    elsif assignment_type == 'reviewer' && reviewer.nil?
      update(reviewer: current_user)
    elsif assignment_type == 'reviewer' && second_reviewer.nil? && reviewer&.id == self.user.id
      return('The Second Reviewer cannot also be the Reviewer.')
    elsif assignment_type == 'second_reviewer' && second_reviewer.nil?
      update(second_reviewer: current_user)
    else
      return(error_messages[assignment_type])
    end

    return 'Entry taken'
  end

  def return_complaint(current_user, assignment_type)
    return("Already completed") if status == 'COMPLETED'

    case assignment_type
    when 'assignee'
      return("Not yet assigned") if user.display_name == 'Vrt Incoming'

      if !is_important
        return("Currently assigned to someone else") if user.id != current_user.id

        update(user: User.vrtincoming, status: "NEW")
        complaint.set_status("NEW")
      elsif is_important && status != "PENDING"
        update(user: User.vrtincoming, status: "NEW")
        complaint.set_status("NEW")
      else
        return("Status is pending")
      end
    when 'reviewer'
      return('Someone else is currently reviewing') if reviewer&.id != current_user.id

      update(reviewer: nil)
    when 'second_reviewer'
      return('Someone else is currently reviewing') if second_reviewer&.id != current_user.id

      update(second_reviewer: nil)
    end

    'Entry returned'
  end

  def unassign(assignment_type)
    return("Complaint is already assigned to Vrt Incoming") if user == User.vrtincoming

    case assignment_type
    when 'assignee'
      if !is_important
        return("Already completed") if status == 'COMPLETED'

        update(user: User.vrtincoming, status: "NEW")
        complaint.set_status("NEW")
      elsif is_important && status != "PENDING"
        update(user: User.vrtincoming, status: "NEW")
        complaint.set_status("NEW")
      else
        return("Status is pending")
      end
    when 'reviewer'
      update(reviewer: nil)
    when 'second_reviewer'
      update(second_reviewer: nil)
    end

    "Unassigned the Complaint's #{assignment_type}"
  end

  def reassign(assignee, assignment_type)
    return("Complaint is already assigned to #{assignee.cvs_username}") if user == assignee
    return("#{reviewer.cvs_username} is already reviewing Complaint") if user == reviewer
    return("#{second_reviewer.cvs_username} is already the second reviewer for Complaint") if user == second_reviewer

    case assignment_type
    when 'assignee'
      if !is_important
        return("Already completed") if status == "COMPLETED"

        update(user: assignee, status: "ASSIGNED", case_assigned_at: Time.now)
        complaint.set_status("ASSIGNED") unless complaint.status == "ASSIGNED"
      elsif is_important && status != "PENDING"
        update(user: assignee, status: "ASSIGNED", case_assigned_at: Time.now)
        complaint.set_status("ASSIGNED") unless complaint.status == "ASSIGNED"
      else
        return("Status is pending")
      end
    when 'reviewer'
      update(reviewer: assignee)
    when 'second_reviewer'
      update(second_reviewer: assignee)
    end

    "#{assignee.cvs_username} assigned to Complaint as #{assignment_type}"
  end

  def is_pending?
    "PENDING" == status
  end

  def uri_or_ip
    uri.present? ? uri : ip_address
  end

  # Returns the Wbrs::Prefix objects.
  # Object may be cached.
  # @param [String] prefix_given please give us the prefix to use, or we'll use the domain or ip_address field.
  # @param [Boolean] reload set to true to get an up to date call to the API.
  # @return [Array[Wbrs::Prefix]] the object for the Prefix remote stub.
  def remote_prefixes(prefix_given: self.hostlookup, reload: false)
    @remote_prefixes = nil if reload
    # IPv6 cannot be parsed like URI, since it does not follow rfc3986 (URLs standard)
    # If it is IPv6, do not escape prefix and add brackets to transform it to url
    escaped_prefix = !!(prefix_given =~ Resolv::IPv6::Regex) ? "[#{prefix_given}]" : Addressable::URI.escape(prefix_given)
    @remote_prefixes ||= Wbrs::Prefix.where({:urls => [escaped_prefix]})
  end

  # Returns the Wbrs::Prefix object called on domain_of_with_path
  # Object may be cached.
  # @param [String] prefix_given please give us the prefix to use, or we'll use the domain or ip_address field.
  # @param [Boolean] reload set to true to get an up to date call to the API.
  # @return [Array[Wbrs::Prefix]] the object for the Prefix remote stub.
  def remote_prefixes_with_path(prefix_given: self.hostlookup, reload: false)
    @remote_prefixes_with_path = nil if reload
    @remote_prefixes_with_path ||= Wbrs::Prefix.where({:urls => [DisputeEntry.domain_of_with_path(prefix_given)]})
  end

  #################################################################################################################
  # CATEGORY CHANGING SECTION
  #################################################################################################################

  def categorize_simple(prefix,
                        categories_string,
                        category_names_string,
                        entry_status,
                        comment,
                        resolution_comment,
                        uri_as_categorized,
                        current_user,
                        commit_pending,
                        self_review)

    # not important case or resolution is "unchanged"
    current_status = STATUS_COMPLETED
    self.case_assigned_at ||= Time.now
    # TODO categories_string is list of ids, but db uses list of names which is in category_names_string
    update!(resolution: entry_status,
            url_primary_category: categories_string,
            category: categories_string,
            status: current_status,
            internal_comment: comment,
            resolution_comment: resolution_comment,
            uri_as_categorized: uri_as_categorized,
            case_resolved_at: Time.now,user:current_user)
    complaint.set_status(current_status)


    #this is where we should send off the category to the API
    if ![STATUS_RESOLVED_FIXED_INVALID,STATUS_RESOLVED_FIXED_UNCHANGED].include?(entry_status) && categories_string.present?
      existing_prefixes = remote_prefixes(prefix_given: prefix)
      commit_category(existing_prefixes,
                      ip_or_uri: prefix,
                      categories_string: categories_string,
                      description: comment,
                      user: current_user.email,
                      casenumber: self.complaint.id )
      update!(url_primary_category: category_names_string, category: category_names_string, uri_as_categorized: uri_as_categorized)
    else
      # TODO Do we need to update the record when we are not making a change?
      existing_prefixes = remote_prefixes(prefix_given: prefix)
      cat_from_wbrs = self.set_current_category_from_prefix(existing_prefixes)
      update!(url_primary_category: cat_from_wbrs, category: cat_from_wbrs)
    end

  end

  def categorize_important(prefix,
                           categories_string,
                           category_names_string,
                           entry_status,
                           comment,
                           resolution_comment,
                           uri_as_categorized,
                           current_user,
                           commit_pending,
                           self_review)

    self.case_assigned_at ||= Time.now
    # TODO categories_string is list of ids, but db uses list of names which is in category_names_string
    update!(status:STATUS_COMPLETED,
            category: categories_string,
            internal_comment: comment,
            resolution_comment: resolution_comment,
            uri_as_categorized: uri_as_categorized,
            case_resolved_at: Time.now,
            user:current_user)
    complaint.set_status(STATUS_COMPLETED)
    #this is where we should send off the category to the API

    if self.resolution != STATUS_RESOLVED_FIXED_INVALID && categories_string.present?
      existing_prefixes = remote_prefixes(prefix_given: prefix)
      commit_category(existing_prefixes,
                      ip_or_uri: prefix,
                      categories_string: categories_string,
                      description: comment,
                      user: current_user.email,
                      casenumber: self.complaint.id)
      update!(url_primary_category: category_names_string, category: category_names_string)
    else
      # TODO Do we need to update the record when we are not making a change?
      existing_prefixes = remote_prefixes(prefix_given: prefix)
      cat_from_wbrs = self.set_current_category_from_prefix(existing_prefixes)
      update!(url_primary_category: cat_from_wbrs, category: cat_from_wbrs)
    end

  end


  def post_categorize(current_user)
    WebcatCredits::ComplaintEntries::CreditProcessor.new(current_user, self).process

    if self.status == STATUS_COMPLETED && self.complaint_entry_screenshot.present?
      self.complaint_entry_screenshot.destroy
    end

    return
  end

  def change_category(prefix,
                      categories_string,
                      category_names_string,
                      entry_status,
                      comment,
                      resolution_comment,
                      uri_as_categorized,
                      current_user,
                      commit_pending,
                      self_review)
    ActiveRecord::Base.transaction do

      if categories_string.blank?
        raise "categories string is empty"
      end

      #Although it's more code efficient to put this in one block, i seperated it out for the sake of visual clarity since there's a ton
      # of stuff going on with the categorization workflow

      #First, check if not important.  If not, super simple no guardrails categorization path
      if !self.is_important
        categorize_simple(prefix, categories_string, category_names_string, entry_status, comment, resolution_comment, uri_as_categorized, current_user, commit_pending, self_review)
        return post_categorize(current_user)
      end

      #Second, check to see if this is an unchanged decision, if it is, then there's nothing to guardrails here.
      if entry_status == Complaint::RESOLUTION_UNCHANGED
        categorize_simple(prefix, categories_string, category_names_string, entry_status, comment, resolution_comment, uri_as_categorized, current_user, commit_pending, self_review)
        return post_categorize(current_user)
      end

      #Third if self-review is set to true, then it's not necessary to go through full guard rails workflow (i see this path being potentially worked on later for security reasons)
      if self_review == true
        categorize_simple(prefix, categories_string, category_names_string, entry_status, comment, resolution_comment, uri_as_categorized, current_user, commit_pending, self_review)
        return post_categorize(current_user)
      end

      #################

      #if the code has made it here then it's going to get guardrailed.  First step is to set the categorization attempt to "PENDING" so that it goes into
      # 2nd person review box, which is done here.  This will set it to PENDING, and the next go around it will skip this and head closer to the workflow.
      if self.status != PENDING
        update!(resolution: entry_status,
                url_primary_category: category_names_string,
                status: PENDING,
                internal_comment: comment,
                resolution_comment: resolution_comment,
                uri_as_categorized: uri_as_categorized,
                user:current_user)
        return post_categorize(current_user)
      end

      #if the code has made it here it's because it was in the 2nd person review and failed that review, as in, the peer reviewer did not agree with the
      # category and has denied the commital of the categorization, which effectively sets the ticket back to assigned for the original analyst to keep
      # working on
      if commit_pending != "commit"
        update!(status: ASSIGNED,
                url_primary_category: self.category,
                internal_comment: comment,
                resolution_comment: resolution_comment,
                uri_as_categorized: uri_as_categorized,
                case_assigned_at: Time.now,
                was_dismissed: true)
        return post_categorize(current_user)
      end

      ###  this section deals with the full guardrails of categorizing a high traffic "important" domain

      verdict_pass = true
      verdict_reasons = []

      ## call guardrails

      #begin
        category_ids_array = categories_string.split(',').map {|cat| cat.to_i}

        verdict_results = Webcat::EntryVerdictChecker.new(prefix, category_ids_array).check

        verdict_pass = verdict_results[:verdict_pass]
        verdict_reasons = verdict_results[:verdict_reasons]
        #binding.pry
      #rescue Exception => e
      #  Rails.logger.error(e.message)
      #  verdict_pass = false
      #  verdict_reasons << "there was an api call failure, erring to manager review"
      #end

      ## if verdict does not pass and is not a webcat manager then kickback to manager with why it failed
      if verdict_pass == false
        if !current_user.is_webcat_manager?
          manager_user = User.where(:cvs_username => Complaint::MAIN_WEBCAT_MANAGER_CONTACT).first
          guard_rails_reasons = verdict_reasons.join(";")
          update!(user: manager_user,
                  internal_comment: "FAILED GUARDRAILS! Reason: #{guard_rails_reasons}"
          )
          return post_categorize(current_user)
        end
      end

      ## The remaining logic belows handles a verdict_pass of true or a webcat manager's categorization, which is exempt from verdicts.

      categorize_important(prefix, categories_string, category_names_string, entry_status, comment, resolution_comment, uri_as_categorized, current_user, commit_pending, self_review)

      return post_categorize(current_user)
      ###

    end

  end


  #############################################################################################
  # CATEGORY COMMIT LOGIC
  # ###########################################################################################

  def find_matching_prefix_with_observable(existing_prefixes, ip_or_uri)
    #support for ipv6 carried over from work done in WEB-11015 while this was being developed
    #is_ip_address = !!(uri_or_ip  =~ Resolv::IPv4::Regex)
    is_ip_address = !!(ip_or_uri =~ Resolv::IPv4::Regex || ip_or_uri =~ Resolv::IPv6::Regex)

    url_parts = Complaint.parse_url(ip_or_uri) unless is_ip_address
    existing_prefix = nil
    if existing_prefixes.present? && !is_ip_address
      existing_prefixes.each do |prefix_found|
        ##reconstruct url parts
        reconstructed_uri = ""
        if url_parts[:subdomain].present?
          reconstructed_uri += url_parts[:subdomain] + "."
        end
        reconstructed_uri += url_parts[:domain]
        if url_parts[:path].present?
          reconstructed_uri += url_parts[:path]
        end

        ##reconstruct prefix found
        reconstructed_prefix = ""
        if prefix_found.subdomain.present?
          reconstructed_prefix += prefix_found.subdomain + "."
        end
        reconstructed_prefix += prefix_found.domain
        if prefix_found.path.present?
          reconstructed_prefix += prefix_found.path
        end

        #if prefix_found.subdomain == url_parts[:subdomain]
        if reconstructed_uri == reconstructed_prefix
          #this if statement now seems a bit redundant, but for safet sake, keeping this here
          # note: All of this as well as change_category is getting a big refactor soon.
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

    return existing_prefix

  end

  ####Generic method to handle any logic to alter categories and any other necessary activities before sending categories
  # to RuleAPI
  def pre_commit_processing(category_ids_array, ip_or_uri)

    if category_ids_array.include?(AbusiveContentTool.current_child_abuse_category[:id])
      category_ids_array = AbusiveContentTool.reclassify_abuse_categories(category_ids_array)

      abuse_info = {}
      abuse_info[:user_id] = self.user.id
      abuse_info[:user] = self.user.cvs_username
      abuse_info[:url] = ip_or_uri
      self.abuse_information = abuse_info.to_json
      self.save!
      result = AbusiveContentTool.submit_abuse_to_authorities(self, self.user, SimpleIDN.to_ascii(ip_or_uri))
      abuse_info[:iwf_report] = result[:iwf_report]
      abuse_info[:ncmec_report] = result[:ncmec_report]
      self.abuse_information = abuse_info.to_json
      self.save

      #needs an official notification system here but for right now email talosweb if there is an anomaly
      # in reporting results
      AbuseContentTool.validate_report(self)


      #if result[:status].to_s == "success"
        #move this to the abuse content tool
        #abusive_info = {}
        #abusive_info[:iwf_report_id] = "IWF report submission ID: #{result[:data]}"
        #self.abuse_information = abusive_info.to_json
        #self.save!
        #report_alert_args = {}
        #report_alert_args[:to] = "admatter@cisco.com"
        #report_alert_args[:from] = "noreply@talosintelligence.com"
        #report_alert_args[:subject] = "IWF Report Notification"
        #report_alert_args[:body] = "Reference Data <br /> Complaint ID: #{self.complaint.id} <br /> Complaint Entry ID: #{self.id} <br /> Entry: #{self.hostlookup} <br /> User assigned: #{self.user.cvs_username}"

        #attachments_to_mail = []
        #conn = ::Bridge::SendEmailEvent.new(addressee: 'talos-intelligence')
        #conn.post(report_alert_args, attachments_to_mail)

      #else
      #  raise "Abuse submission issue: #{result[:message]}"
      #end
    end

    return category_ids_array

  end

  #####Generic method to handle any finishing logic that should happen after committing categories to RuleAPI
  def post_commit_processing()

  end

  def commit_category(existing_prefixes, ip_or_uri:, categories_string:, description:, user:, casenumber: nil)

    # Look for existing prefix
    existing_prefix = find_matching_prefix_with_observable(existing_prefixes, ip_or_uri)

    category_ids_array = categories_string.split(',').map {|cat| cat.to_i}

    category_ids_array = pre_commit_processing(category_ids_array, ip_or_uri)

    if description.present? && casenumber.present?
      description = description + "--Case Number: #{casenumber} User: #{user}"
    end

    if existing_prefix.present?
      prefix_object = Wbrs::Prefix.new
      prefix_object.set_categories(category_ids_array, prefix_id: existing_prefix.prefix_id, user: user, description: description)
    else
      Wbrs::Prefix.create_from_url(url: SimpleIDN.to_ascii(ip_or_uri), categories: category_ids_array, user: user, description: description)
    end

    post_commit_processing()
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

  def self.create_wbnp_complaint_entry(complaint, ip_url, url_parts, user = nil, status = NEW, categories = nil, logger_token, platform)

    new_complaint_entry = ComplaintEntry.new
    new_complaint_entry.complaint_id = complaint.id
    new_complaint_entry.status = status

    if platform.present?
      new_complaint_entry.platform_id = platform.id rescue nil
    end

    begin
      Rails.logger.error "#{logger_token} getting sbrs data for uri: #{ip_url}\n"
      wbrs_stuff = Sbrs::ManualSbrs.get_wbrs_data({:url => Addressable::URI.escape(ip_url)})
      wbrs_score = wbrs_stuff["wbrs"]["score"]
      new_complaint_entry.wbrs_score = wbrs_score
    rescue
      Rails.logger.error "#{logger_token} failed getting sbrs data for uri: #{ip_url}\n"
      # do nothing continue with saving the entry
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

      # Parse the ip_url
      Rails.logger.error "#{logger_token} parsing url for uri: #{ip_url}\n"
      parsed_url = Complaint.parse_url(ip_url)

      new_complaint_entry.subdomain = parsed_url[:subdomain]
      new_complaint_entry.domain = parsed_url[:domain]
      new_complaint_entry.path = parsed_url[:path]
    end
    # lets query the top url API endpoint to determine if this is an important site or not
    # but you better believe i dont trust this API so we have some checks to ensure the entry gets created
    begin
      Rails.logger.error "#{logger_token} getting importance for uri: #{ip_url}\n"
      importance = self_importance(ip_url)
      new_complaint_entry.is_important = importance if importance
    rescue
      # do nothing keep building entry
    end
    new_complaint_entry.user = user
    new_complaint_entry.case_assigned_at ||= Time.now if user && user.display_name != "Vrt Incoming"

    Rails.logger.error "#{logger_token} setting categories for dispute entry for uri: #{ip_url}\n"
    if status == PENDING # occurs when attempt to categorized a Top URl without a complaint
      new_complaint_entry.url_primary_category = categories
      new_complaint_entry.category = categories
    else
      current_category = new_complaint_entry.set_current_category
      new_complaint_entry.url_primary_category = current_category
      new_complaint_entry.category = current_category
    end

    new_complaint_entry.save
    ##turning this off for WBNP pulls as it is a suspect in causing sudden thread halts. Fortunately this shouldn't affect SDO for just dealing with WBNP

    #Rails.logger.error "#{logger_token} generating preload for dispute entry #{new_complaint_entry.id.to_s} uri: #{ip_url}\n"
    #ComplaintEntryPreload.generate_preload_from_complaint_entry(new_complaint_entry)
    #turning this off for the time being, until we know for sure screenshots are fully functional, plus this is the wrong screenshot capture anyways
    #delay.capture_screenshot(new_complaint_entry.hostlookup, new_complaint_entry.id)
  end

  class << self
    def capture_screenshot(uri, complaint_entry_id)
      max_wait_for_job = 15 #seconds
      begin
        #screenshot_data =  ""
        #Timeout::timeout(max_wait_for_job) do
        #  screenshot_data = CapybaraSpider.low_capture("#{uri}")
        #end
        #ces = ComplaintEntryScreenshot.new
        #ces.complaint_entry_id = complaint_entry_id
        #ces.screenshot = Base64.decode64(screenshot_data)
        #ces.save!
      rescue Timeout::Error => e
        #couldnt complete in time
        #Rails.logger.error( "#{e} --- Timed out waiting for screenshot for #{uri} to finish")
        #ces = ComplaintEntryScreenshot.new
        #ces.error_message = e.message
        #ces.complaint_entry_id = complaint_entry_id
        #open("app/assets/images/failed_screenshot.jpg") do |f|
        #  ces.screenshot = f.read
        #end
        #ces.save!
      rescue Exception => e
        #Rails.logger.error("#{e.message}")
        #do nothing, it was worth a try. kittens are sad now
        #ces = ComplaintEntryScreenshot.new
        #ces.error_message = e.message
        #ces.complaint_entry_id = complaint_entry_id
        #open("app/assets/images/failed_screenshot.jpg") do |f|
        #  ces.screenshot = f.read
        #end
        #ces.save!
      end

    end
    #handle_asynchronously :capture_screenshot
  end


  def self.create_complaint_entry(complaint, ip_url, platform, user = nil, status = NEW, categories = nil)
    new_complaint_entry = ComplaintEntry.new
    begin
      wbrs_stuff = Sbrs::ManualSbrs.get_wbrs_data({:url => Addressable::URI.escape(ip_url)})
      wbrs_score = wbrs_stuff["wbrs"]["score"]
      new_complaint_entry.wbrs_score = wbrs_score
    rescue Exception => e
      Rails.logger.info (" Couldnt contact SBRS. #{e}")
      new_complaint_entry.wbrs_score = 0
    end
    begin
      new_complaint_entry.complaint_id = complaint.id
      new_complaint_entry.status = status
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
      new_complaint_entry.platform_id = platform.id if platform

      if status == PENDING # occurs when attempt to categorized a Top URl without a complaint
        new_complaint_entry.url_primary_category = categories
        new_complaint_entry.category = categories
      else
        current_category = new_complaint_entry.set_current_category
        new_complaint_entry.url_primary_category = current_category
        new_complaint_entry.category = current_category
      end
      new_complaint_entry.save

      if user != User.where(display_name:"Vrt Incoming").first
        begin
          WebcatCredits::ComplaintEntries::CreditProcessor.new(user, new_complaint_entry).process
        rescue Exception => e
          Rails.logger.error e.message
          Rails.logger.error e.backtrace.join("\n")
        end

      end
    rescue Exception => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
      raise Exception.new("{ComplaintEntry creation error: {content: #{ip_url},error:#{e}}}")
    end
    begin
      ComplaintEntryPreload.generate_preload_from_complaint_entry(new_complaint_entry)
    rescue Exception => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
    end

    max_wait_for_job = 15 #seconds
    ###this should be eventually removed, but commenting out for now to see if it speeds up the NEW button for bulk entries

    #begin
      #this is where screen grabs happen.
    #  screenshot_entry = ComplaintEntryScreenshot.create!(complaint_entry_id:new_complaint_entry.id)
    #  screenshot_entry.grab_screenshot
    #rescue Timeout::Error => e
      #couldnt complete in time
    #  Rails.logger.error( "#{e} --- Timed out waiting for screenshot for #{new_complaint_entry.hostlookup} to finish")
    #  ces = ComplaintEntryScreenshot.new
    #  ces.error_message = e.message
    #  ces.complaint_entry_id = new_complaint_entry.id
    #  open("app/assets/images/failed_screenshot.jpg") do |f|
    #   ces.screenshot = f.read
    #  end
    #  ces.save!
    #rescue Exception => e
    #  Rails.logger.error("#{e.message}")
      # do nothing, it was worth a try. kittens are sad now
    #  ces = ComplaintEntryScreenshot.new
    #  ces.error_message = e.message
    #  ces.complaint_entry_id = new_complaint_entry.id
    #  open("app/assets/images/failed_screenshot.jpg") do |f|
    #   ces.screenshot = f.read
    #  end
    #  ces.save!
    #end
  end

  # Searches in a variety of ways.
  # advanced -- search by supplied field.
  # named -- call a saved search.
  # standard -- use a pre-defined search.
  # contains -- search many fields where supplied value is contained in the field.
  # nil -- all records.
  # @param [String] search_type variety of search
  # @param [ActionController::Parameters, Hash, NilClass] params supplied fields and values for search.
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
        contains_search(params['value'])
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
    complaint_entry_fields = %w{complaint_entries.complaint_id subdomain domain path url_primary_category
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
        new_entries
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
      when "MANAGER QUEUE"
        joins(:complaint).where(user_id: User.webcat_manager_ids).where("complaint_entries.status not in ('COMPLETED','RESOLVED','NEW')")
      when "NEW JIRA"
          where(status: 'NEW', complaint_id: Complaint.from_jira)
      when "JIRA OVERDUE"
        where(complaint_id: Complaint.from_jira).where.not(status:["RESOLVED", "COMPLETED"]).where("created_at < ?",Time.now - 12.hours)
      when "JIRA ASSIGNED"
        where(status: 'ASSIGNED', complaint_id: Complaint.from_jira)
      when "ALL JIRA"
        where(complaint_id: Complaint.from_jira)
      when "ALL TALOS"
        where(complaint_id: Complaint.from_ti)
      when "NEW TALOS"
        where(status: 'NEW', complaint_id: Complaint.from_ti)
      when "TALOS OVERDUE"
        where(complaint_id: Complaint.from_ti).where.not(status:["RESOLVED", "COMPLETED"]).where("created_at < ?",Time.now - 12.hours)
      when "TALOS ASSIGNED"
        where(status: 'ASSIGNED', complaint_id: Complaint.from_ti)
      when "ALL WBNP"
        where(complaint_id: Complaint.from_wbnp)
      when "NEW WBNP"
        where(status: 'NEW', complaint_id: Complaint.from_wbnp)
      when "WBNP OVERDUE"
        where(complaint_id: Complaint.from_wbnp).where.not(status:["RESOLVED", "COMPLETED"]).where("created_at < ?",Time.now - 12.hours)
      when "WBNP ASSIGNED"
        where(status: 'ASSIGNED', complaint_id: Complaint.from_wbnp)
      when "ALL INTERNAL"
        where(complaint_id: Complaint.from_int)
      when "NEW INTERNAL"
        where(status: 'NEW', complaint_id: Complaint.from_int)
      when "INTERNAL OVERDUE"
        where(complaint_id: Complaint.from_int).where.not(status:["RESOLVED", "COMPLETED"]).where("created_at < ?",Time.now - 12.hours)
      when "INTERNAL ASSIGNED"
        where(status: 'ASSIGNED', complaint_id: Complaint.from_int)
      when "ALL PENDING"
        where(status: 'PENDING')
      when "PENDING OVERDUE"
        where(status: 'PENDING').where("created_at < ?",Time.now - 12.hours)
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
    return false unless named_search
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
  # @param [ActionController::Parameters, Hash, NilClass] params supplied fields and values for search.
  # @param [String] search_name name to save this search as a saved search.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.advanced_search(params, search_name:, user:)
    present_params = params.select{|ignore_key, value| value.present?}

    if present_params['status'].present?
      present_params['status'] = present_params['status'].split(',').map {|item| item.strip }
    end

    if present_params['resolution'].present?
      present_params['resolution'] = present_params['resolution'].split(',').map {|item| item.strip }
    end

    if present_params['id'].present?
      present_params['id'] = present_params['id'].split(',').map {|item| item.strip }
    end

    if present_params['complaint_id'].present?
      present_params['complaint_id'] = present_params['complaint_id'].split(',').map {|item| item.strip }
    end

    if present_params['channel'].present?
      present_params['channel'] = present_params['channel'].split(',').map {|item| item.strip }
    end

    if present_params['ip_or_uri'].present?
      present_params['ip_or_uri'] = present_params['ip_or_uri'].split(',').map {|item| item.strip }
    end

    if present_params['user_id'].present?
      present_params['user_id'] = present_params['user_id'].split(',').map {|item| item.strip }
    end

    if present_params['jira_id'].present?
      present_params['jira_id'] = present_params['jira_id'].split(',').map {|item| item.strip}
    end

    simple_params = present_params.slice(*%w{id complaint_id resolution status})

    relation = where(simple_params)

    if params['user_id'].present?

      relation =
          relation.joins(:user).where(:users => { cvs_username: present_params['user_id']})
    end
    
    if params['jira_id'].present?
      relation = relation.joins(complaint: {import_urls: :jira_import_task}).where(jira_import_tasks: {issue_key: present_params['jira_id']})
    end

    if params['platform_ids'].present?
      ids = params['platform_ids'].split(',').map {|m| m.to_i}
      relation = relation.joins(:complaint).where("complaints.platform_id in (:ids) or complaint_entries.platform_id in (:ids)", ids: ids)
    end

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
      relation = relation.joins(complaint: :complaint_tags).where(complaint_tags: {name: params['tags'].split(',').map {|item| item.strip }})
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
        relation = relation.where(customers: {name: customer_params['customer_name'].split(',').map {|item| item.strip }})
      end

      if customer_params['customer_email'].present?
        relation = relation.where(customers: {email: customer_params['customer_email']})
      end

      if company_name.present?
        relation = relation.where(companies: {name: company_name.split(',').map {|item| item.strip }})
      end
    end

    category = present_params['category']
    if category.present?
      relation = relation.where('category like :category', category: "%#{category}%")
    end

    ip_or_uri = present_params['ip_or_uri']
    if ip_or_uri.present?
      vals = ip_or_uri.map{ |e| "'#{e}'"}.join(',')
      relation = relation.where("complaint_entries.domain in (#{vals})")
                         .or(where("complaint_entries.ip_address in (#{vals})"))
                         .or(where("complaint_entries.uri in (#{vals})"))
    end

    complaint_fields = present_params.to_h.slice(*%w{description channel})

    if present_params['submitter_type'].present?
      submitter_type_params = present_params['submitter_type'].split(', ').map(&:upcase).uniq.reduce([]) do |memo, type|
        if type == Complaint::SUBMITTER_TYPE_CUSTOMER
          memo << Complaint::SUBMITTER_TYPE_CUSTOMER
        else 'GUEST'
          memo.push(Complaint::SUBMITTER_TYPE_NONCUSTOMER, nil)
        end
        memo
      end
      complaint_fields.merge!(submitter_type: submitter_type_params)
    end

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

  # Assigns self.category field to list of categories (descr field) from WBRS.
  # @return [String] Comma separated list of category descr fields.
  def set_current_category_from_prefix(prefix_results)
    if prefix_results
      if prefix_results.first&.is_active == 1

        qualified_prefixes =
            prefix_results.find_all {|result| result.path == self.path && result.subdomain == (self.subdomain || '')}
        category_names = Wbrs::Prefix.category_names(qualified_prefixes)

        self.url_primary_category = category_names
        self.category = category_names
      end
    end

    self.category
  rescue => except

    Rails.logger.warn "Populating categories from Wbrs failed."
    Rails.logger.warn except
    Rails.logger.warn except.backtrace.join("\n")

    ''
  end

  def set_current_category
    set_current_category_from_prefix(Wbrs::Prefix.where({:urls => [Addressable::URI.escape(self.hostlookup)]}))
  end

  def self.get_category_data(uri)
    prefix_results = Wbrs::Prefix.where({:urls => [uri]})

    return {} unless prefix_results.any?

    parsed_uri = Complaint.parse_url(uri)
    parsed_uri['path'] = ''
    parsed_uri['subdomain'] = ''
    parsed_uri['path'] = parsed_uri[:path] unless parsed_uri[:path].blank?
    parsed_uri['subdomain'] = parsed_uri[:subdomain] unless parsed_uri[:subdomain].blank?

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
    prefix_results = remote_prefixes    # Should use self.domain

    if self.entry_type == 'URI/DOMAIN'
      parsed_uri = Complaint.parse_url(uri)

      return [] unless prefix_results

      parsed_uri['path'] = '' unless parsed_uri['path'].present?
      parsed_uri['subdomain'] = '' unless parsed_uri['subdomain'].present?

      qualified_prefixes = prefix_results.find_all do |prefix_result|
        ((prefix_result.subdomain == parsed_uri['subdomain']) || (parsed_uri['subdomain'] == 'www')) && prefix_result.path == parsed_uri['path']
      end

      category_names =
          if qualified_prefixes.any?
            Wbrs::Prefix.category_names(qualified_prefixes)
          else
            []
          end

      category_names
    elsif self.entry_type == 'IP'
      raise ("Cannot inherit categories for IP entries.")
    end
  end

  def current_category_data

    prefix_results = remote_prefixes_with_path
    return {} unless prefix_results
    domain_of = DisputeEntry.domain_of_with_path(self.hostlookup)
    certainty_on_urls = Wbrs::Prefix.get_certainty_sources_for_urls([domain_of])

    qualified_prefixes = prefix_results.find_all do |result|
      result.path == self.path && ((result.subdomain == (self.subdomain || '')) || (self.subdomain == 'www'))
    end

    final_current_categories = {}

    qualified_prefixes.each do |result|
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

  def self.current_category_data_for_uri(uri)
    prefix = Wbrs::Prefix.where({:urls => [Addressable::URI.escape(uri)]})&.first
    return {} unless prefix

    current_categories = prefix.categories

    current_categories.inject({}) do |data, category|
      data[category.category_id] = {
          category_id: category.category_id,
          desc_long: category.desc_long,
          descr: category.descr,
          mnem: category.mnem,
          is_active: category.is_active,
          confidence: category.confidence
      }
      data
    end
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
    ids_checked = []
    prefixes = remote_prefixes
    prefixes.each do |prefix|
      unless ids_checked.include?(prefix.id)
        if prefix.subdomain == (self.subdomain || '') && prefix.path == self.path
          prefix_id = prefix.prefix_id
          response = Wbrs::HistoryRecord.where({:prefix_id => prefix_id}).sort_by {|history| DateTime.parse(history.time)}.reverse
          response.each do |resp|
            prefix_history << resp
          end
          ids_checked << prefix_id
        end
      end
    end

    prefix_history
  end

  def history_category_data_with_preload_save

    prefix_id = nil
    prefix_results = Wbrs::Prefix.where({:urls => [Addressable::URI.escape(self.hostlookup)]})

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

      if self.complaint.ticket_source != ::Complaint::SOURCE_RULEUI
        message = Bridge::ComplaintUpdateStatusEvent.new
        message.post_complaint(self.complaint)
      end

      return true
    else
      return false
    end
  end

  def process_resolution_changes(resolution, internal_comment, customer_facing_comment, current_user)
    confirmation = {}
    if !["COMPLETED","PENDING"].include?(self.status) && resolution != "REOPENED"
      if self.is_important && resolution != "UNCHANGED"
        self.update(status: "PENDING", resolution: resolution, internal_comment: internal_comment, resolution_comment: customer_facing_comment)
        confirmation.update(state: 'SUCCESS', host: self.hostlookup, status: self.status, resolution: resolution, internal_comment: internal_comment, customer_facing_comment: customer_facing_comment,
                            message: "Successfully processed a resolution update of #{resolution} on Complaint Entry (#{self.hostlookup}) of status #{self.status}")
      else
        self.update(status: "COMPLETED", resolution: resolution, internal_comment: internal_comment, resolution_comment: customer_facing_comment)
        confirmation.update(state: 'SUCCESS', host: self.hostlookup, status: self.status, resolution: resolution, internal_comment: internal_comment, customer_facing_comment: customer_facing_comment,
                            message: "Successfully processed a resolution update of #{resolution} on Complaint Entry (#{self.hostlookup}) of status #{self.status}")
      end
      # Error catch: cannot set a ComplaintEntry to "REOPENED" unless it has a status of "COMPLETED"
    elsif self.status != "COMPLETED" && resolution == "REOPENED"
      confirmation.update(state: 'ERROR', host: self.hostlookup, status: self.status,resolution: resolution, internal_comment: internal_comment, customer_facing_comment: customer_facing_comment,
                          message: "Cannot process a status update of #{resolution} on Complaint Entry (#{self.hostlookup}) of status #{self.status}")
    elsif self.status == "COMPLETED" && resolution == "REOPENED"
      self.update(status: "REOPENED", resolution: nil)
      confirmation.update(state: 'SUCCESS', host: self.hostlookup, status: self.status, resolution: resolution, internal_comment: internal_comment, customer_facing_comment: customer_facing_comment,
                          message: "Successfully processed a status update of #{resolution} on Complaint Entry (#{self.hostlookup}) of status #{self.status}")
    else
      # Error catch: cannot update a ComplaintEntry's resolution if it has a status of "COMPLETED" or "PENDING"
      confirmation.update(state: 'ERROR', host: self.hostlookup, status: self.status,resolution: resolution, internal_comment: internal_comment, customer_facing_comment: customer_facing_comment,
                          message: "Cannot process a resolution update to #{resolution} on Complaint Entry (#{self.hostlookup})  of status #{self.status}")
    end

    # add credit for user's contribution to complaint entry
    WebcatCredits::ComplaintEntries::CreditProcessor.new(current_user, self).process
    confirmation
  end

  def as_report_row
    report_entry = JSON.parse(self.to_json)

    platform = self.determine_platform

    report_entry.delete("platform")
    report_entry.delete("platform_id")
    report_entry["platform"] = platform

    report_entry
  end

  def resubmit_to_rule_api
    log_messages = []
    #do some sanity checks ot make sure it's not already categorized

    if !["completed","resolved"].include?(self.status.downcase)
      log_messages << "complaint entry #{self.id} : #{self.hostlookup} is not resolved yet, not attempting resend"
      return log_messages
    end
    all_cats = Wbrs::Category.all
    if self.category.blank?
      log_messages << "complaint entry #{self.id} : #{self.hostlookup} has no categories saved, cannot attempt resubmit"
      return log_messages
    end
    cat_string = self.category.split(",").map {|cat| cat.strip }
    cat_ids_array = []

    cat_string.each do |cat_s|
      possible_cat = all_cats.select {|cat| cat.descr == cat_s}
      if possible_cat.present?
        cat_ids_array << possible_cat.first.category_id
      end
    end
    cat_ids_string = cat_ids_array.join(",")

    current_cats = Wbrs::Prefix.where({:urls => [Addressable::URI.escape(self.uri_as_categorized)]}).map {|result| result.category_id}

    if current_cats.sort == cat_ids_array.sort
      log_messages << "#{self.id} : #{self.hostlookup} current cat ids appear to match cat ids in ruleAPI, aborting resubmit"
      return log_messages
    end
    final_prefix = ""
    if self.uri_as_categorized.present?
      log_messages << "#{self.id} : #{self.hostlookup} using uri_as_categorized: #{self.uri_as_categorized}"
      final_prefix = self.uri_as_categorized
    else
      log_messages << "#{self.id} : #{self.hostlookup} could not find uri_as_categorized, using hostlookup"
      final_prefix = self.hostlookup
    end
    #setup for call to ruleAPI
    existing_prefixes = Wbrs::Prefix.where({:urls => [Addressable::URI.escape(self.uri_as_categorized)]})
    prefix = self.uri_as_categorized
    final_cat_string = cat_ids_string
    comment = self.internal_comment + " -- automated re-attempt at categorization"
    ticket_user = User.find(self.user_id)
    log_messages << "#{self.id} : #{self.hostlookup} committing category #{cat_string} : #{cat_ids_string} to ruleAPI"
    commit_category(existing_prefixes, ip_or_uri: prefix, categories_string: final_cat_string, description: comment, user: ticket_user.email, casenumber: self.complaint.id)

    return log_messages
  end

  def determine_platform
    if self.platform_id.present?
      return (self.product_platform.public_name rescue "No Data")
    end
    if self.complaint.platform_id.present?
      return (self.complaint.platform.public_name rescue "No Data")
    end
    if self.platform.present?
      return (self.platform rescue "No Data")
    end

    return nil
  end

  def ti_status
    if self.status == STATUS_WEBCAT_DUPLICATE
      return PENDING
    else
      return self.status
    end
  end
end
