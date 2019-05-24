class TiApi::AmpNamingPattern < TiApi::Base
  attr_reader :data_set

  class DataElement
    include ActiveModel::Model
    attr_accessor :pattern_params, :prev_position, :record

    def to_ti_params
      {
          old_position: prev_position,
          pattern: record.pattern,
          example: record.example,
          description: record.engine_description,
          notes: record.public_notes,
          position: record.table_sequence,
          engine: record.engine,
      }
    end
  end

  def initialize(pattern_params_ary)

    # Loop through array of params, collect the previous position, and assign params to the record.
    # Store in an array of DataElement objects which have these three data items.
    @data_set = pattern_params_ary.map do |pattern_params|
      record =
          if pattern_params['id'].present?
            ::AmpNamingConvention.where(id: pattern_params['id']).first || ::AmpNamingConvention.new
          else
            ::AmpNamingConvention.new
          end

      prev_position = record.table_sequence

      attribute_values = pattern_params.slice(*AmpNamingConvention.column_names)
      attribute_values.delete('id')
      record.assign_attributes(attribute_values)
      raise "Invalid record for #{record.pattern} -- #{record.errors.full_messages.to_sentence}" unless record.valid?

      DataElement.new( pattern_params: attribute_values,
                       prev_position: prev_position,
                       record: record )
    end
  end

  def records
    data_set.map{ |data_elem| data_elem.record }
  end

  def update_ti!
    naming_pattern_set = data_set.map {|data_elem| data_elem.to_ti_params}
    input = {
        ticode: Rails.configuration.talos_intelligence.api_key,
        amp_naming_pattern: naming_pattern_set
    }
    self.class.call_request(:put, 'api/v1/amp_naming_patterns', input: input)
  end
end
