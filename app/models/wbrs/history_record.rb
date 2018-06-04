class Wbrs::HistoryRecord < Wbrs::Base
  attr_accessor :prefix, :category, :action, :confidence, :description, :event_id, :time, :user

  delegate :prefix_id, to: :prefix, :allow_nil => true
  delegate :category_id, to: :category, :allow_nil => true

  def self.new_from_datum(datum)
    prefix_id = datum.delete('prefix_id')
    prefix = Wbrs::Prefix.find(prefix_id)
    unless prefix
      rules = Rule.get_where('prefix_id' => prefix_id, 'limit' => 1)
      prefix = rules.first&.prefix
    end

    category = Wbrs::Category.find(datum.delete('category_id'))

    new(datum.merge('category' => category, 'prefix' => prefix))
  end

  # Get the rules from given criteria.
  # example: get_where(category_ids = [11], active: true)
  # @param [Integer] prefix_id: the prefixes id
  # @param [Integer] limit: Max number of records to return
  # @param [Integer] offset: Offset of the first record to return
  # @return [Array<Wbrs::HistoryRecord>] Array of the results.
  def self.get_where(conditions = {})
    params = stringkey_params(conditions)
    response = post_request(path: '/v1/cat/rules/audit', body: params)

    response_body = JSON.parse(response.body)
    response_body['data'].map {|datum| new_from_datum(datum)}
  end
end
