class Wbrs::RuleHit < Wbrs::Base
  FIELD_NAMES = %w{desc_long description mnemonic probability is_active rule_hit}
  FIELD_SYMS = FIELD_NAMES.map{|name| name.to_sym}

  attr_accessor *FIELD_SYMS

  alias_method(:id, :rule_hit)

  def initialize(attributes = {})
    if attributes.keys.present?
      attributes.keys.each do |attr|
        if !FIELD_NAMES.include?(attr)
          self.class.module_eval { attr_accessor attr.to_sym}
        end
      end
    end
    super
  end

  def self.new_from_datum(datum)
    new(datum)
  end

  # Get all the categories.
  # @return [Array<Wbrs::Category>] Array of the results.
  def self.all(reload: false)
    unless @all || reload
      response = call_json_request(:get, '/v1/rulehits/info', body: '')

      response_body = JSON.parse(response.body)
      @all = response_body['data'].map {|datum| new_from_datum(datum)}
    end
    @all
  end

end
