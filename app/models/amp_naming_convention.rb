class AmpNamingConvention < ApplicationRecord
  validates :pattern, :example, :engine, :engine_description, presence: true
  validates :table_sequence, presence: true, numericality: { only_integer: true }
  # DB unique index enforces: validates :table_sequence, uniqueness: true

  def self.save_batch(records)
    # Since table_sequence might be reordered, but must be unique at all times,
    # move to negative of its intended position, then negate it again.
    records.each do |record|
      record.table_sequence = -record.table_sequence
      record.save!
    end
    records.each do |record|
      record.table_sequence = -record.table_sequence
      record.save!
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
