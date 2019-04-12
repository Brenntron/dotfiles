# class FileReputationTicket < ApplicationRecord
class FileReputationDispute < ApplicationRecord
  belongs_to :customer, optional:true
  delegate :name, :company, :company_id, to: :customer, allow_nil: true, prefix: true
  
  STATUS_NEW                = 'NEW'
  STATUS_ASSIGNED           = 'ASSIGNED'
  STATUS_CLOSED             = 'CLOSED'

  DISPOSITION_MALICIOUS     = 'MALICIOUS'

  validates :status, :file_name, :sha256_hash, :disposition_suggested, presence: true

  def self.create_action(bugzilla_rest_session, sha256_hash, file_name, file_size, sample_type, disposition_suggested, source, platform, sha256_checksum)

    file_rep = FileReputationDispute.new

    threat_score = nil
    threatgrid_private = nil
    if sha256_checksum.present?
      threatgrid_response = Threatgrid::Search.query(sha256_checksum)

      threat_score = threatgrid_response['threat_score']
      threatgrid_private = threatgrid_response['threatgrid_private']
    end

    summary = "New File Rep Dispute generated at #{DateTime.now.utc.strftime("%Y-%m-%d %H:%M")}"

    full_description = %Q{
          File name: #{file_name};
          SHA256 hash: #{sha256_hash}
    }

    bug_attrs = {
        'product' => 'Escalations Console',
        'component' => 'FileRep',
        'summary' => summary,
        'version' => 'unspecified',
        'description' => full_description,
        'priority' => "P3",
        'classification' => 'unclassified',
    }

    bug_proxy = bugzilla_rest_session.create_bug(bug_attrs)

    customer = Customer.where(name: 'Dispute Analyst').first
    attributes = {
        id: bug_proxy.id,
        sha256_hash: sha256_hash,
        file_name: file_name,
        file_size: file_size,
        sample_type: sample_type,
        disposition_suggested: disposition_suggested,
        source: source,
        platform: platform,
        threatgrid_score: threat_score,
        threatgrid_private: threatgrid_private,
        customer: customer
    }
    file_rep.assign_attributes(attributes)

    if file_rep.save
      file_rep
    else
      error_messages = file_rep.errors.full_messages.join('; ')
      render plain: "\"Error(s) creating file rep -- #{error_messages}\"", status: :internal_server_error
    end
  end

  def self.save_named_search(search_name, params, user:, project_type:)
    NamedSearchCriterion.where(named_search_id: NamedSearch.where(user_id: user.id, name: search_name).ids).delete_all

    found_search = user.named_searches.where(name: search_name).first
    named_search = found_search || NamedSearch.create!(user: user, name: search_name, project_type: project_type)

    params.each do |field_name, value|
      case
      when value.kind_of?(Hash)
        value.each do |sub_field_name, sub_value|
          named_search.named_search_criteria.create(field_name: "#{field_name}~#{sub_field_name}", value: sub_value)
        end
      when 'search_type' == field_name
        #do nothing
      when 'search_name' == field_name
        #do nothing
      else
        named_search.named_search_criteria.create(field_name: field_name, value: value)
      end
    end
  end

  # Searches based on supplied fields and values.
  # Optionally takes a name to save this search as a saved search.
  # @param [ActionController::Parameters] params supplied fields and values for search.
  # @param [String] search_name name to save this search as a saved search.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.advanced_search(params, search_name:, user:)

    dispute_fields = params.to_h.slice(*FileReputationDispute.column_names)

    relation = where(dispute_fields)

    # Save this search as a named search
    if params.present? && search_name.present?
      save_named_search(search_name, params, user: user, project_type: 'FileReputationDispute')
    end

    relation
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

  # Searches based on standard pre-determined filters.
  # @param [String] search_name name of the filter.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.standard_search(search_name, user:)
    case search_name
    # when 'recently_viewed'
    #   joins(:dispute_peeks).where(dispute_peeks: {assigned_id: user.id})
    when 'my_open'
      where.not(status: STATUS_CLOSED).where(assigned_id: user.id)
    when 'my_disputes'
      where(assigned_id: user.id)
    # when 'team_disputes'
    #   where(assigned_id: user.my_team)
    when 'unassigned'
      where(assigned_id: nil).where.not(status: STATUS_CLOSED)
    when 'open'
      where.not(status: STATUS_CLOSED)
    # when 'open_email'
    #   sbrs_disputes.where(status: [STATUS_NEW, STATUS_REOPENED, STATUS_CUSTOMER_PENDING, STATUS_CUSTOMER_UPDATE, STATUS_ON_HOLD, STATUS_RESEARCHING, STATUS_ESCALATED, STATUS_ASSIGNED])
    # when 'open_web'
    #   wbrs_disputes.where(status: [STATUS_NEW, STATUS_REOPENED, STATUS_CUSTOMER_PENDING, STATUS_CUSTOMER_UPDATE, STATUS_ON_HOLD, STATUS_RESEARCHING, STATUS_ESCALATED, STATUS_ASSIGNED])
    when 'closed'
      where(status: STATUS_CLOSED)
    when 'all'
      where({})
    else
      raise "No search named '#{search_name}' known."
    end
  end

  # Searches many fields in the record for values containing a given value.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.contains_search(value)
    contains_fields = %w{file_reputation_disputes.id source platform file_name sha256_hash description}
    contains_where = contains_fields.map{|field| "#{field} like :pattern"}.join(' or ')

    customer_where = %w{name email}.map{|field| "customers.#{field} like :pattern"}.join(' or ')
    company_where = 'companies.name like :pattern'

    where_str = "#{contains_where} or #{customer_where} or #{company_where}"
    left_joins(customer: :company).where(where_str, pattern: "%#{value}%")
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
      contains_search(params['value'])
    else
      where({})
    end
  end

end
