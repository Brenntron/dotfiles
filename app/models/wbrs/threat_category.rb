class Wbrs::ThreatCategory < Wbrs::Base
  FIELD_NAMES = %w{category_id desc_long desc mnem is_active}
  FIELD_SYMS = FIELD_NAMES.map{|name| name.to_sym}

  attr_accessor *FIELD_SYMS

  alias_method(:id, :category_id)

  def self.new_from_datum(datum)
    datum['category_id'] = datum.delete('category') if datum['category'].present?
    new(datum)
  end

  # Get all the threat categories.
  # @return [Array<Wbrs::ThreatCategory>] Array of the results.
  def self.all(reload: false)
    unless @all || reload
      response = call_json_request(:get, '/v1/rep/thrtcats', body: '')

      response_body = JSON.parse(response.body)
      @all = response_body['data'].map {|datum| new_from_datum(datum)}
    end
    @all
  end

  def self.selections
    @selections ||= all.sort_by { |thrt_cat| thrt_cat.desc }.map{ |thrt_cat| [thrt_cat.desc, thrt_cat.id] }
  end
end
