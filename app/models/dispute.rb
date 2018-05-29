class Dispute < ApplicationRecord

  # Searches based on supplied fields and values.
  # Optionally takes a name to save this search as a saved search.
  # @param [ActionController::Parameters] params supplied fields and values for search.
  # @param [String] search_name name to save this search as a saved search.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.advanced_search(params, search_name:, base_relation: Dispute)
    raise 'Search must use ActionController::Parameters!' unless params.kind_of?(ActionController::Parameters)
    raise 'Cannot search with unpermitted parameters!' unless params.permitted?
    base_relation.where(params)
  end

  # Searched based on saved search.
  # @param [String] search_name the name of the saved search.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.named_search(search_name, base_relation: Dispute)
    named_search = NamedSearch.where(name: search_name).first
    search_params = named_search.named_search_criteria.inject({}) do |search_params, criterion|
      search_params[criterion.field_name] = criterion.value
      search_params
    end
    base_relation.where(search_params)
  end

  # Searches based on standard pre-determined filters.
  # @param [String] search_name name of the filter.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.standard_search(search_name, base_relation: Dispute)
    case search_name
      when 'Open'
        base_relation.where(status: 'Open')
      when 'Closed'
        base_relation.where(status: 'Closed')
      else
        base_relation.where({})
    end
  end

  # Searches many fields in the record for values containing a given value.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.contains_search(value, base_relation: Dispute)
    base_relation.where("customer_name like :pattern" +
                            " or resolution like :pattern" +
                            " or customer_company_name like :pattern",
                        pattern: "%#{value}%")
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
  def self.robust_search(search_type, params:, search_name:, base_relation: Dispute)
    case search_type
      when 'advanced'
        advanced_search(params, search_name: search_name, base_relation: base_relation)
      when 'named'
        named_search(search_name, base_relation: base_relation)
      when 'standard'
        standard_search(search_name, base_relation: base_relation)
      when 'contains'
        contains_search(params[:value], base_relation: base_relation)
      else
        base_relation.where({})
    end
  end
end

