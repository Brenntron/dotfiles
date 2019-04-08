# class FileReputationTicket < ApplicationRecord
class FileReputationDispute < ApplicationRecord
  belongs_to :customer, optional:true
  delegate :name, :company, :company_id, to: :customer, allow_nil: true, prefix: true

  STATUS_NEW                = 'NEW'
  STATUS_ASSIGNED           = 'ASSIGNED'
  STATUS_CLOSED             = 'CLOSED'

  DISPOSITION_MALICIOUS     = 'MALICIOUS'

  validates :status, :file_name, :sha256_hash, :disposition_suggested, presence: true

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
