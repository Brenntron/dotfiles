# class FileReputationTicket < ApplicationRecord
class FileReputationDispute < ApplicationRecord
  belongs_to :customer, optional:true
  delegate :name, :company, :company_id, to: :customer, allow_nil: true, prefix: true

  # Searches in a variety of ways.
  # advanced -- search by supplied field.
  # named -- call a saved search.
  # standard -- use a pre-defined search.
  # contains -- search many fields where supplied value is contained in the field.
  # nil -- all records.
  # @param [String] search_type variety of search
  # @param [ActionController::Parameters] params supplied fields and values for search.
  # @param [String] search_name name of saved search.
  # @return [ActiveRecord::Relation]
  def self.robust_search(search_type, search_name: nil, params: nil)
    if search_type
      where(params || {status: search_name})
    else
      where({})
    end
  end
end
