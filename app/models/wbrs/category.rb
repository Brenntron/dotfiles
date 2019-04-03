class Wbrs::Category < Wbrs::Base
  FIELD_NAMES = %w{category_id desc_long descr mnem is_active}
  FIELD_SYMS = FIELD_NAMES.map{|name| name.to_sym}

  attr_accessor *FIELD_SYMS

  alias_method(:id, :category_id)

  def self.new_from_datum(datum)
    datum['category_id'] = datum.delete('category') if datum['category'].present?
    new(datum.slice(*FIELD_NAMES))
  end

  # Get all the categories.
  # @return [Array<Wbrs::Category>] Array of the results.
  def self.all(reload: false)
    unless @all || reload
      response = call_request(:get, '/v1/cat/categories', input: '')

      response_body = JSON.parse(response.body)
      @all = response_body['data'].map {|datum| new_from_datum(datum)}
    end
    @all
  end

  def self.mnem_lookup_hash
    @mnem_lookup_hash || all.inject({}) do |lookup_hash, cat|
      lookup_hash[cat.mnem] = cat
      lookup_hash
    end
  end

  # Lookup ThreatCategory by mnem
  # @param [String] mnem The mnem field of a threat category
  # @return [Wbrs::ThreatCategory]
  def self.lookup_by_mnem(mnem)
    mnem_lookup_hash[mnem]
  end

  # Get a category by id
  # @param [Integer] id the category id
  # @return [Wbrs::Category] the category
  def self.find(id)
    all&.find { |cat| cat.category_id == id }
  end

  def self.category_ids(categories_given)
    case categories_given
      when Wbrs::Category
        [ categories_given.id ]
      when Array
        categories_given.map do |category|
          case category
            when Wbrs::Category
              category.id
            else
              category
          end
        end
      when NilClass
        nil
      else #integer
        [ categories_given ]
    end
  end

  def self.get_category_ids(category_array)
    categories = Wbrs::Category.all
    category_ids = []
    categories.each do |cat|
      if category_array.include?(cat.category_id.to_s)
        category_ids << cat.category_id
      end
    end
    category_ids
  end

  def self.category_ids_from_params(params)
    category_ids(params.delete('categories') || params.delete('category_ids') || params.delete('category_id'))
  end
end
