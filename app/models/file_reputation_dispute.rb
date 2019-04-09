# class FileReputationTicket < ApplicationRecord
class FileReputationDispute < ApplicationRecord

  belongs_to :customer, optional:true
  belongs_to :assigned, class_name: 'User', optional:true

  delegate :name, :company, :company_id, to: :customer, allow_nil: true, prefix: true

  STATUS_NEW                = 'NEW'
  STATUS_ASSIGNED           = 'ASSIGNED'
  STATUS_CLOSED             = 'CLOSED'

  DISPOSITION_MALICIOUS     = 'MALICIOUS'

  validates :status, :file_name, :sha256_hash, :disposition_suggested, presence: true

  # Searches based on standard pre-determined filters.
  # @param [String] search_name name of the filter.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.standard_search(search_name, user:)
    case search_name
    # when 'recently_viewed'
    #   joins(:dispute_peeks).where(dispute_peeks: {user_id: user.id})
    # when 'my_open'
    #   where.not(status: STATUS_RESOLVED).where(user_id: user.id)
    when 'my_disputes'
      where(user_id: user.id)
    # when 'team_disputes'
    #   where(user_id: user.my_team)
    # when 'unassigned'
    #   where(status: [STATUS_NEW, STATUS_REOPENED], user_id: User.where(display_name: 'Vrt Incoming').first.id)
    # when 'open'
    #   where(status: [STATUS_NEW, STATUS_REOPENED, STATUS_CUSTOMER_PENDING, STATUS_CUSTOMER_UPDATE, STATUS_ON_HOLD, STATUS_RESEARCHING, STATUS_ESCALATED, STATUS_ASSIGNED])
    # when 'open_email'
    #   sbrs_disputes.where(status: [STATUS_NEW, STATUS_REOPENED, STATUS_CUSTOMER_PENDING, STATUS_CUSTOMER_UPDATE, STATUS_ON_HOLD, STATUS_RESEARCHING, STATUS_ESCALATED, STATUS_ASSIGNED])
    # when 'open_web'
    #   wbrs_disputes.where(status: [STATUS_NEW, STATUS_REOPENED, STATUS_CUSTOMER_PENDING, STATUS_CUSTOMER_UPDATE, STATUS_ON_HOLD, STATUS_RESEARCHING, STATUS_ESCALATED, STATUS_ASSIGNED])
    when 'closed'
      where(status: [STATUS_CLOSED])
    when 'all'
      where({})
    else
      raise "No search named '#{search_name}' known."
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
      contains_search(params['value'])
    else
      where({})
    end
  end
end
