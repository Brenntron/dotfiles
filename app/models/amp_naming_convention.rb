class AmpNamingConvention < ApplicationRecord
  validates :pattern, :example, :engine, :engine_description, presence: true
  validates :table_sequence, presence: true, numericality: { only_integer: true }
  # DB unique index enforces: validates :table_sequence, uniqueness: true

  def self.from_params(pattern_params_ary)
    # Loop through array of params, collect the previous position, and assign params to the record.
    # Store in an array of DataElement objects which have these three data items.
    @data_set = pattern_params_ary.map do |pattern_params|
      record =
          if pattern_params['id'].present?
            ::AmpNamingConvention.where(id: pattern_params['id']).first || ::AmpNamingConvention.new
          else
            ::AmpNamingConvention.new
          end

      attribute_values = pattern_params.slice(*AmpNamingConvention.column_names)
      attribute_values.delete('id')
      record.assign_attributes(attribute_values)
      raise "Invalid record for #{record.pattern} -- #{record.errors.full_messages.to_sentence}" unless record.valid?

      record
    end
  end

  def self.create_from_params(pattern_params_ary)
    records = from_params(pattern_params_ary)
    records.each {|rec| rec.save!}
  end

  def self.save_from_params(pattern_params_ary)
    records = from_params(pattern_params_ary)
    records.each do |rec|
      rec.table_sequence = -rec.table_sequence
      rec.save!
    end
    records.each do |rec|
      rec.table_sequence = -rec.table_sequence
      rec.save!
    end
  end

  def self.send_all_to_ti
    amp_patterns = all.map do |record|
      attrs = record.attributes.slice(*%w[pattern example engine_description notes table_sequence engine])
      attrs['description'] = attrs.delete('engine_description')
      attrs['position'] = attrs.delete('table_sequence')
      attrs
    end
    message = Bridge::AmpPatternUpdateEvent.new
    message.post(amp_patterns: amp_patterns)
  end
end
