class Wbrs::Category < Wbrs::Base
  FIELD_NAMES = %w{category_id desc_long descr mnem is_active}
  FIELD_SYMS = FIELD_NAMES.map{|name| name.to_sym}

  SERVICE_STATUS_NAME = "RULEAPI:CATEGORY"
  attr_accessor *FIELD_SYMS

  alias_method(:id, :category_id)

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

  def self.service_status
    @service_status ||= ServiceStatus.where(:name => SERVICE_STATUS_NAME).first
  end

  def service_status
    @service_status ||= ServiceStatus.where(:name => SERVICE_STATUS_NAME).first
  end

  def self.system_reload
    begin
      RuntimeConfig.get_category_reload
    rescue
      false
    end
  end

  def self.new_from_datum(datum)
    datum['category_id'] = datum.delete('category') if datum['category'].present?
    new(datum)
  end

  # Get all the categories.
  # @return [Array<Wbrs::Category>] Array of the results.
  def self.all(reload: false)
    service_status_data = {}
    unless @all.present? || reload || system_reload
      response = call_json_request(:get, '/v1/cat/categories', body: '')
      response_body = JSON.parse(response.body) rescue {}
      @all = response_body['data'].map {|datum| new_from_datum(datum)}
      #retry 3 times, otherwise push alert to system
      if @all.blank?
        (0..2).each do
          response = call_json_request(:get, '/v1/cat/categories', body: '')
          response_body = JSON.parse(response.body) rescue {}
          @all = response_body['data'].map {|datum| new_from_datum(datum)}
          if @all.present?
            break
          end
        end
      end

      if @all.blank?

        service_status_data[:type] = "outage"
        service_status_data[:exception] = "/v1/cat/categories not loading or responding"
        service_status_data[:exception_details] = response.error rescue response.body

        service_status.log(service_status_data)
      else
        service_status_data[:type] = "working"
        service_status.log(service_status_data)
      end


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
