class Wbrs::HistoryRecord < Wbrs::Base
  attr_accessor :prefix_id, :category, :action, :confidence, :description, :event_id, :time, :user

  delegate :category_id, to: :category, :allow_nil => true

  def prefix
    @prefix ||= Wbrs::Prefix.find(prefix_id)
  end

  def self.new_from_datum(datum)
    category = Wbrs::Category.find(datum.delete('category_id'))

    new(datum.merge('category' => category))
  end

  # Get the rules from given criteria.
  # example: get_where(category_ids = [11], active: true)
  # @param [Integer] prefix_id: the prefixes id
  # @param [Integer] limit: Max number of records to return
  # @param [Integer] offset: Offset of the first record to return
  # @return [Array<Wbrs::HistoryRecord>] Array of the results.
  def self.where(conditions = {})
    params = stringkey_params(conditions)
    response = post_request(path: '/v1/cat/rules/audit', body: params)

    response_body = JSON.parse(response.body)
    result = response_body['data'].map {|datum| new_from_datum(datum)}
    response_body['data'].map {|datum| new_from_datum(datum)}
  end
end
