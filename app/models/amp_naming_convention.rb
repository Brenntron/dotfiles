class AmpNamingConvention < ApplicationRecord
  validates :pattern, :example, :engine, :engine_description, presence: true
  validates :table_sequence, presence: true, numericality: { only_integer: true }
  # DB unique index enforces: validates :table_sequence, uniqueness: true

  def self.save_batch(records)
    byebug
    delete_all
    records.each {|rec| rec.save!}
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
