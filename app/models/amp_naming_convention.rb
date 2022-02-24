class AmpNamingConvention < ApplicationRecord
  validates :pattern, :example, :private_engine_description, :engine_description, presence: true
  validates :table_sequence, presence: true, numericality: { only_integer: true }
  after_destroy :ensure_valid_table_sequence
  after_create :ensure_valid_table_sequence
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
    if AmpNamingConvention.exists?
      table_sequence = AmpNamingConvention.maximum(:table_sequence)
    else
      table_sequence = 0
    end

    pattern_params_ary.each do |pattern_params|
      table_sequence += 1
      pattern_params[:table_sequence] = table_sequence
    end

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

  # Note: pass timestamp argument to insure that timestamp is determined within transaction.
  def self.send_all_to_ti(timestamp:)
    amp_patterns = all.map do |record|
      attrs = record.attributes.slice(*%w[pattern example engine_description table_sequence])
      attrs['notes'] = record.public_notes
      attrs['description'] = attrs.delete('engine_description')
      attrs['position'] = attrs.delete('table_sequence')
      attrs['message_timestamp'] = timestamp.utc.iso8601
      attrs
    end
    message = Bridge::AmpPatternUpdateEvent.new
    message.post(amp_patterns: amp_patterns)
  rescue => ex
    if ex.message.present?
      raise
    else
      raise ex.class, ex.class.name
    end
  end

  private

  def ensure_valid_table_sequence
    records = AmpNamingConvention.all.order(table_sequence: :asc)
    records.each_with_index do |rec, index|
      rec.table_sequence = index + 1
      rec.save!
    end
  end
end
