class Dispute < ApplicationRecord

  # Searches based on supplied fields and values.
  # Optionally takes a name to save this search as a saved search.
  # @param [ActionController::Parameters] params supplied fields and values for search.
  # @param [String] search_name name to save this search as a saved search.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.advanced_search(params, search_name:, user:)
    raise 'Search must use ActionController::Parameters!' unless params.kind_of?(ActionController::Parameters)
    raise 'Cannot search with unpermitted parameters!' unless params.permitted?

    present_params = params.select{ |key, value| value.present? }

    # Save this search as a named search
    if present_params.present? && search_name.present?
      named_search =
          user.named_searches.where(name: search_name).first || NamedSearch.create!(user: user, name: search_name)
      NamedSearchCriterion.where(named_search: named_search).delete_all
      present_params.each do |field_name, value|
        named_search.named_search_criteria.create(field_name: field_name, value: value)
      end
    end

    where(present_params)
  end

  # Searched based on saved search.
  # @param [String] search_name the name of the saved search.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.named_search(search_name, user:)
    named_search = user.named_searches.where(name: search_name).first
    raise "No search named '#{search_name}' found." unless named_search
    search_params = named_search.named_search_criteria.inject({}) do |search_params, criterion|
      search_params[criterion.field_name] = criterion.value
      search_params
    end
    where(search_params)
  end

  # Searches based on standard pre-determined filters.
  # @param [String] search_name name of the filter.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.standard_search(search_name)
    case search_name
      when 'Open'
        where(status: 'Open')
      when 'Closed'
        where(status: 'Closed')
      else
        raise "No search named '#{search_name}' known."
    end
  end

  # Searches many fields in the record for values containing a given value.
  # @param [ActiveRecord::Relation] base_relation relation to chain this search onto.
  # @return [ActiveRecord::Relation]
  def self.contains_search(value)
    searchable_fields = %w{case_number case_guid customer_name customer_email customer_phone customer_company_name
                           org_domain subject description problem_summary research_notes}
    where_str = searchable_fields.map{|field| "#{field} like :pattern"}.join(' or ')
    where(where_str, pattern: "%#{value}%")
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
  def self.robust_search(search_type, params: nil, search_name: nil, user:)
    case search_type
      when 'advanced'
        advanced_search(params, search_name: search_name, user: user)
      when 'named'
        named_search(search_name, user: user)
      when 'standard'
        standard_search(search_name)
      when 'contains'
        contains_search(params['value'])
      else
        where({})
    end
  end
end

