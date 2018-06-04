class Wbrs::Category < Wbrs::Base
  attr_accessor :category_id, :desc_long, :descr, :mnem
  class << self
    attr_reader :all
  end

  alias_method(:id, :category_id)

  def self.new_from_datum(datum)
    datum['category_id'] = datum.delete('category')
    new(datum)
  end

  # Get all the categories.
  # @return [Array<Wbrs::Category>] Array of the results.
  def self.all(reload: false)
    unless @all || reload
      response = get_request(path: '/v1/cat/categories', body: '')

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
end
