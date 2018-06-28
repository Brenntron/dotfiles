class Wbrs::Category < Wbrs::Base
  FIELD_NAMES = %w{category_id desc_long descr mnem}
  FIELD_SYMS = FIELD_NAMES.map{|name| name.to_sym}

  attr_accessor *FIELD_SYMS

  alias_method(:id, :category_id)

  def self.new_from_datum(datum)
    datum['category_id'] = datum.delete('category') if datum['category'].present?
    new(datum)
  end

  # Get all the categories.
  # @return [Array<Wbrs::Category>] Array of the results.
  def self.all(reload: false)
    unless @all || reload
      response = call_json_request(:get, '/v1/cat/categories', body: '')

      response_body = JSON.parse(response.body)
      @all = response_body['data'].map {|datum| new_from_datum(datum)}
    end
    @all
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
      else #integer
        [ categories_given ]
    end
  end

  def self.category_ids_from_params(params)
    category_ids(params.delete('categories') || params.delete('category_ids') || params.delete('category_id'))
  end
end