class Wbrs::HistoryRecord < Wbrs::Base
  attr_accessor :prefix_id, :category, :action, :confidence, :description, :event_id, :time, :user

  delegate :category_id, to: :category, :allow_nil => true

  SERVICE_STATUS_NAME = "RULEAPI:CATEGORY_HISTORY"

  def self.service_status
    @service_status ||= ServiceStatus.where(:name => SERVICE_STATUS_NAME).first
  end

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
    service_status_data = {}
    params = stringkey_params(conditions)
    response = post_request(path: '/v1/cat/rules/audit', body: params)

    response_body = JSON.parse(response.body) rescue {}
    
    records = response_body['data'].map {|datum| new_from_datum(datum)}

    if records.blank? && response.code >= 300
      (0..2).each do
        response = post_request(path: '/v1/cat/rules/audit', body: params)
        response_body = JSON.parse(response.body) rescue {}
        records = response_body['data'].map {|datum| new_from_datum(datum)}

        if records.present? || response.code < 300
          break
        end
      end
    end

    if records.blank? && response.code >= 300
      service_status_data[:type] = "outage"
      service_status_data[:exception] = "/v1/cat/rules/audit not loading or responding"
      service_status_data[:exception_details] = response.error rescue response.body

      service_status.log(service_status_data)
    else
      service_status_data[:type] = "working"
      service_status.log(service_status_data)
    end
  end
end
